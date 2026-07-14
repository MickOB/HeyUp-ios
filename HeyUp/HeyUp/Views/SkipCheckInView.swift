import SwiftUI

struct SkipCheckInView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("CHECKING IN").font(.system(size: 14, weight: .bold)).foregroundColor(HeyUpColor.accent)
            Text("Two breaks skipped in a row")
                .font(.system(size: 32, weight: .heavy)).multilineTextAlignment(.center).frame(maxWidth: 320)
            Text("Totally fine — want the next one easier? Fewer reps, simpler exercise.")
                .font(.system(size: 17)).foregroundColor(HeyUpColor.textSecondary)
                .multilineTextAlignment(.center).frame(maxWidth: 300)
            VStack(spacing: 12) {
                Button("Yes, make it easier") { vm.easeUpAfterSkips() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("No, keep as is") { vm.keepGoingAfterSkips() }
                    .buttonStyle(SecondaryPillStyle())
            }
            .frame(maxWidth: 300)
            .padding(.top, 8)
            Spacer()
        }
        .padding(28)
    }
}
