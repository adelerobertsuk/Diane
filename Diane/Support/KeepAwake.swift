import UIKit

/// Stops the phone going to sleep mid-sentence. Gemini's lock-screen
/// cutoff is the whole reason this exists.
enum KeepAwake {
    static func start() {
        UIApplication.shared.isIdleTimerDisabled = true
        UIDevice.current.isProximityMonitoringEnabled = false
    }

    static func stop() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
