import Foundation
import UserNotifications

/// Wraps local notification permission + scheduling for the break timer.
/// Two notifications per session: a 1-minute warning, and one for when the
/// break actually starts (in case the app isn't in the foreground).
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    static let yorkshireVoiceCueKey = "heyup-yorkshire-voice-cue"
    private let warningID = "heyup-warning"
    private let breakID = "heyup-break-ready"

    private var yorkshireVoiceCueEnabled: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.yorkshireVoiceCueKey) != nil else { return true }
        return defaults.bool(forKey: Self.yorkshireVoiceCueKey)
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Schedules the pair of notifications for a session that lasts
    /// `totalSeconds` from now. Call `cancelAll()` first if a previous
    /// session's notifications might still be pending (e.g. user paused/skipped).
    func scheduleSessionNotifications(totalSeconds: TimeInterval, session: SessionType) {
        cancelAll()
        guard totalSeconds > 0 else { return }

        let center = UNUserNotificationCenter.current()
        if totalSeconds > 60 {
            let warningContent = UNMutableNotificationContent()
            warningContent.title = "HeyUp"
            warningContent.body = session.oneMinuteWarning()
            warningContent.sound = .default
            let warningTrigger = UNTimeIntervalNotificationTrigger(timeInterval: totalSeconds - 60, repeats: false)
            let warningRequest = UNNotificationRequest(identifier: warningID, content: warningContent, trigger: warningTrigger)
            center.add(warningRequest) { error in
                if let error { print("Unable to schedule HeyUp warning: \(error)") }
            }
        }

        let breakContent = UNMutableNotificationContent()
        breakContent.title = "HeyUp"
        breakContent.body = "Time to move — your break is ready."
        breakContent.sound = yorkshireVoiceCueEnabled
            ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "heyup.caf"))
            : .default
        let breakTrigger = UNTimeIntervalNotificationTrigger(timeInterval: totalSeconds, repeats: false)
        let breakRequest = UNNotificationRequest(identifier: breakID, content: breakContent, trigger: breakTrigger)

        center.add(breakRequest) { error in
            if let error { print("Unable to schedule HeyUp break notification: \(error)") }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [warningID, breakID])
    }

#if DEBUG
    func scheduleVoiceCueTest() {
        let content = UNMutableNotificationContent()
        content.title = "HeyUp"
        content.body = "Test complete — your Yorkshire voice cue is working."
        content.sound = yorkshireVoiceCueEnabled
            ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "heyup.caf"))
            : .default
        let request = UNNotificationRequest(
            identifier: "heyup-voice-cue-test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
#endif
}
