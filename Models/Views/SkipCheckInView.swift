import SwiftUI

struct SkipCheckInView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("CHECKING IN").font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.accent)
            Text("Two breaks skipped in a row")
                .font(.system(size: 24, weight: .heavy)).multilineTextAlignment(.center).frame(maxWidth: 280)
            Text("Totally fine — want the next one easier? Fewer reps, simpler exercise.")
                .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 270)
            VStack(spacing: 10) {
                Button("Yes, make it easier") { vm.easeUpAfterSkips() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("No, keep as is") { vm.keepGoingAfterSkips() }
                    .buttonStyle(SecondaryPillStyle())
            }
            .frame(maxWidth: 260)
            .padding(.top, 6)
            Spacer()
        }
        .padding(28)
    }
}
