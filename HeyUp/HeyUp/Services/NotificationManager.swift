import Foundation
import UserNotifications

/// Wraps local notification permission + scheduling for the break timer.
/// Two notifications per session: a 1-minute warning, and one for when the
/// break actually starts (in case the app isn't in the foreground).
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let warningID = "heyup-warning"
    private let breakID = "heyup-break-ready"

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
        guard totalSeconds > 60 else { return } // too short for a useful 1-min warning

        let warningContent = UNMutableNotificationContent()
        warningContent.title = "HeyUp"
        warningContent.body = session.oneMinuteWarning()
        warningContent.sound = .default
        let warningTrigger = UNTimeIntervalNotificationTrigger(timeInterval: totalSeconds - 60, repeats: false)
        let warningRequest = UNNotificationRequest(identifier: warningID, content: warningContent, trigger: warningTrigger)

        let breakContent = UNMutableNotificationContent()
        breakContent.title = "HeyUp"
        breakContent.body = "Time to move — your break is ready."
        breakContent.sound = .default
        let breakTrigger = UNTimeIntervalNotificationTrigger(timeInterval: totalSeconds, repeats: false)
        let breakRequest = UNNotificationRequest(identifier: breakID, content: breakContent, trigger: breakTrigger)

        let center = UNUserNotificationCenter.current()
        center.add(warningRequest)
        center.add(breakRequest)
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [warningID, breakID])
    }
}
