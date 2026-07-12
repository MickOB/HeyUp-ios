import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    Button("‹ Back") { vm.closeSettings() }
                        .buttonStyle(SecondaryPillStyle())
                    Text("Settings").font(.system(size: 22, weight: .heavy))
                }

                group("BREAK EXERCISE") {
                    VStack(spacing: 8) {
                        ForEach(ExerciseType.allCases) { ex in
                            exerciseCard(ex)
                        }
                    }
                    if vm.exercise == .both {
                        comboPicker
                    }
                }

                group("REPS PER BREAK") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                        ForEach([5, 10, 15, 20, 25], id: \.self) { n in
                            Button("\(n)") { vm.repGoal = n }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(vm.repGoal == n ? .black : HeyUpColor.textSecondary)
                                .frame(height: 46).frame(maxWidth: .infinity)
                                .background(vm.repGoal == n ? HeyUpColor.accent : HeyUpColor.card)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(vm.repGoal == n ? HeyUpColor.accent : HeyUpColor.border))
                        }
                    }
                }

                Button("Change name or age (redo onboarding)") {
                    vm.screen = .onboarding
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HeyUpColor.textMuted)
                .frame(maxWidth: .infinity).frame(height: 44)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(HeyUpColor.border))

                Button("Reset today's stats") {
                    vm.statsStore.resetToday()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HeyUpColor.warn)
                .frame(maxWidth: .infinity).frame(height: 44)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(red: 0.227, green: 0.165, blue: 0.141)))
            }
            .padding(20)
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
            content()
        }
    }

    private func exerciseCard(_ ex: ExerciseType) -> some View {
        let selected = vm.exercise == ex
        return Button {
            vm.exercise = ex
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.displayName).font(.system(size: 16, weight: .semibold)).foregroundColor(HeyUpColor.textPrimary)
                    Text(exerciseDescription(ex)).font(.system(size: 12.5)).foregroundColor(HeyUpColor.textMuted)
                }
                Spacer()
                Circle()
                    .strokeBorder(selected ? HeyUpColor.accent : HeyUpColor.border, lineWidth: selected ? 6 : 2)
                    .background(Circle().fill(HeyUpColor.background))
                    .frame(width: 20, height: 20)
            }
            .padding(16).background(HeyUpColor.card).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? HeyUpColor.accent : HeyUpColor.border, lineWidth: selected ? 1.5 : 1))
        }
    }

    private func exerciseDescription(_ ex: ExerciseType) -> String {
        switch ex {
        case .squats: return "Stand facing the camera, squat down and up"
        case .seatedSquat: return "Stand up from your seat, no hands — easiest start"
        case .wallPushup: return "Push-ups against a wall — gentlest on wrists/shoulders"
        case .kneePushup: return "Push-ups from your knees — a step up from wall"
        case .floorPushup: return "Full push-ups on the floor"
        case .mix: return "Rotates through all exercises, one per break"
        case .both: return "\(vm.comboUpper.displayName) then \(vm.comboLower.displayName)"
        }
    }

    private var comboPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Push-up style").font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint)
            FlowLayout(spacing: 6) {
                ForEach([ExerciseType.wallPushup, .kneePushup, .floorPushup]) { ex in
                    Button(ex.displayName) { vm.comboUpper = ex }
                        .buttonStyle(ChipButtonStyle(selected: vm.comboUpper == ex))
                }
            }
            Text("Squat style").font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint).padding(.top, 4)
            FlowLayout(spacing: 6) {
                ForEach([ExerciseType.squats, .seatedSquat]) { ex in
                    Button(ex.displayName) { vm.comboLower = ex }
                        .buttonStyle(ChipButtonStyle(selected: vm.comboLower == ex))
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.063, green: 0.075, blue: 0.035))
        .cornerRadius(14)
    }
}
