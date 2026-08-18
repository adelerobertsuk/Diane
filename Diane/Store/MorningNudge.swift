import Foundation
import UserNotifications

enum MorningNudge {
    static let identifier = "diane.morning"

    static let delegate = Delegate()

    static func prepare() {
        let center = UNUserNotificationCenter.current()
        center.delegate = delegate
    }

    static func refresh(enabled: Bool, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    guard granted else { return }
                    schedule(hour: hour, minute: minute)
                }
            case .authorized, .provisional, .ephemeral:
                schedule(hour: hour, minute: minute)
            default:
                break
            }
        }
    }

    private static func schedule(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Diane"
        content.body = "Stay. Speak. Then you can go."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    final class Delegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .sound, .list]
        }
    }
}
