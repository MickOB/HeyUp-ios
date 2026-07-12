import SwiftUI

/// Shared color palette — matches the HTML prototype (dark, lime accent).
enum HeyUpColor {
    static let background = Color(red: 0.05, green: 0.055, blue: 0.027)   // #0C0E07-ish
    static let card = Color(red: 0.082, green: 0.094, blue: 0.063)         // #151810
    static let border = Color(red: 0.137, green: 0.157, blue: 0.098)      // #232819
    static let accent = Color(red: 0.776, green: 0.949, blue: 0.306)      // #C6F24E
    static let accentHover = Color(red: 0.863, green: 0.980, blue: 0.494) // #DCFA7E
    static let textPrimary = Color(red: 0.949, green: 0.961, blue: 0.925) // #F2F5EC
    static let textSecondary = Color(red: 0.784, green: 0.820, blue: 0.737) // #C9D1BC
    static let textMuted = Color(red: 0.608, green: 0.643, blue: 0.549)   // #9BA48C
    static let textFaint = Color(red: 0.486, green: 0.522, blue: 0.439)   // #7C8570
    static let warn = Color(red: 0.753, green: 0.541, blue: 0.463)        // #C08A76
}

/// Root switch: onboarding until a profile exists, then the main app.
struct RootView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            HeyUpColor.background.ignoresSafeArea()
            switch vm.screen {
            case .onboarding: OnboardingView()
            case .home: HomeView()
            case .history: HistoryView()
            case .timer: TimerView()
            case .getReady: GetReadyView()
            case .movementBreak: MovementBreakView()
            case .skipCheckIn: SkipCheckInView()
            case .success: SuccessView()
            case .settings: SettingsView()
            }
        }
        .foregroundColor(HeyUpColor.textPrimary)
        .onChange(of: scenePhase) { _, newPhase in
            // The in-app countdown Timer can be suspended while backgrounded;
            // catch it up against the wall clock the moment we're active again
            // (see HeyUpViewModel.refreshTimerIfNeeded for why this is safe).
            if newPhase == .active {
                vm.refreshTimerIfNeeded()
            }
        }
    }
}
