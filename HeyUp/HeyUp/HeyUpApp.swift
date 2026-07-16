import SwiftUI
import UserNotifications

final class HeyUpAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// iOS normally hides local notifications while their app is open.
    /// HeyUp's timer commonly finishes in the foreground, so explicitly show
    /// the break banner and play its selected sound in that state as well.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

@main
struct HeyUpApp: App {
    @UIApplicationDelegateAdaptor(HeyUpAppDelegate.self) private var appDelegate
    @StateObject private var viewModel = HeyUpViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
