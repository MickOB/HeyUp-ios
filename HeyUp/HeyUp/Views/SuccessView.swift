import SwiftUI

struct SuccessView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    private var compliments: [String] {
        let nm = vm.profile.name.isEmpty ? "" : ", \(vm.profile.name)"
        return ["Way to go\(nm)", "Strong work\(nm)", "Your back thanks you", "Better than a coffee", "That's how it's done\(nm)", "Blood's flowing again"]
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("✓")
                .font(.system(size: 42, weight: .heavy))
                .frame(width: 88, height: 88)
                .background(HeyUpColor.accent)
                .foregroundColor(.black)
                .clipShape(Circle())
            Text(vm.sessionType.successHeadline())
                .font(.system(size: 26, weight: .heavy)).multilineTextAlignment(.center).frame(maxWidth: 260)
            Text(doneSummary)
                .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted)
            if vm.statsStore.streak > 0 {
                HStack(spacing: 6) {
                    Circle().fill(HeyUpColor.accent).frame(width: 8, height: 8)
                    Text("\(vm.statsStore.streak)-day streak").font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(HeyUpColor.card).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(HeyUpColor.border))
            }
            Spacer()
            Text("Next block starts automatically…")
                .font(.system(size: 12)).foregroundColor(HeyUpColor.textFaint)
                .padding(.bottom, 24)
        }
        .padding(24)
    }

    private var doneSummary: String {
        let compliment = compliments[vm.statsStore.today.completed % compliments.count]
        if vm.exercise == .both {
            return "\(compliment) — \(vm.repGoal) \(vm.comboUpper.displayName.lowercased()) + \(vm.repGoal) \(vm.comboLower.displayName.lowercased()) done."
        }
        return "\(compliment) — \(vm.repGoal) \(vm.currentExercise.displayName.lowercased()) done."
    }
}
