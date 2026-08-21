import Foundation
import UserNotifications

enum MorningNudge {
    static let identifier = "diane.morning"
    static let testIdentifier = "diane.morning.test"

    static let delegate = Delegate()

    static func prepare() {
        UNUserNotificationCenter.current().delegate = delegate
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

    /// Fires a banner in a few seconds so Adele can prove notifications work.
    static func sendTest() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [testIdentifier])

        func enqueue() {
            let content = UNMutableNotificationContent()
            content.title = "Diane"
            content.body = "Just checking in. Stay a minute when morning comes."
            content.sound = .default
            content.interruptionLevel = .active

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(
                identifier: testIdentifier,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted { enqueue() }
                }
            case .authorized, .provisional, .ephemeral:
                enqueue()
            default:
                break
            }
        }
    }

    static func authorizationLabel(completion: @escaping (String) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let label: String
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                label = "Notifications are on."
            case .denied:
                label = "Notifications are off. iPhone Settings, Notifications, Diane, Allow."
            case .notDetermined:
                label = "Diane will ask for permission when you turn Wake on."
            @unknown default:
                label = "Check iPhone Settings, Notifications, Diane."
            }
            DispatchQueue.main.async { completion(label) }
        }
    }

    private static func schedule(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Diane"
        content.body = "Stay. Speak. Then you can go."
        content.sound = .default
        // .active is reliable. Time Sensitive needs a special entitlement we do not ship yet.
        content.interruptionLevel = .active

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
