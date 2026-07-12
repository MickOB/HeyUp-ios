import SwiftUI

@main
struct HeyUpApp: App {
    @StateObject private var viewModel = HeyUpViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
