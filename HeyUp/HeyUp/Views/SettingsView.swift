import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @Environment(\.openURL) private var openURL
    @AppStorage(NotificationManager.yorkshireVoiceCueKey) private var yorkshireVoiceCueEnabled = true

    var body: some View {
        Group {
            if vm.settingsSub == .exercise {
                exerciseSubScreen
            } else {
                mainSettings
            }
        }
    }

    private var mainSettings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    Button("‹ Back") { vm.closeSettings() }
                        .buttonStyle(SecondaryPillStyle())
                    Text("Settings").font(.system(size: 33, weight: .heavy))
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 5) {
                        Button("Support") {
                            openURL(URL(string: "https://heyup-support.mickbrown562.chatgpt.site/#support")!)
                        }
                        Button("Privacy") {
                            openURL(URL(string: "https://heyup-support.mickbrown562.chatgpt.site/#privacy")!)
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HeyUpColor.accent)
                }

                group("HEYUP PLAN") {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vm.hasProAccess ? "Pro is active" : "Free plan")
                                .font(.system(size: 17, weight: .bold))
                            if !vm.hasProAccess {
                                Text(vm.introBreakCompleted
                                     ? "\(vm.freeBreaksRemaining) of \(vm.freeBreakLimit) free breaks remaining this week"
                                     : "Your introductory break is ready")
                                    .font(.system(size: 13))
                                    .foregroundColor(HeyUpColor.textMuted)
                            }
                        }
                        Spacer()
                        if !vm.hasProAccess {
                            Button("View Pro") { vm.openPaywall(returningTo: .settings) }
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(HeyUpColor.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(15)
                    .background(HeyUpColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))

                    Button("Restore purchases") {
                        Task { await vm.purchaseManager.restorePurchases() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HeyUpColor.accent)

                    if vm.hasProAccess {
                        Button("Manage subscription") {
                            openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HeyUpColor.accent)
                    }
                }

                group("I'M SETTLING IN FOR") {
                    HStack(spacing: 4) {
                        ForEach(SessionType.allCases) { t in
                            Button(t.label) { vm.sessionType = t }
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(t == vm.sessionType ? .black : HeyUpColor.textMuted)
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(t == vm.sessionType ? HeyUpColor.accent : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                    .padding(4)
                    .background(HeyUpColor.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }

                group("REMIND ME EVERY") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach([20, 30, 45, 60, 90, 120], id: \.self) { m in
                            Button("\(m) min") { vm.intervalMinutes = m }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(vm.intervalMinutes == m ? .black : HeyUpColor.textMuted)
                                .frame(height: 38).frame(maxWidth: .infinity)
                                .background(vm.intervalMinutes == m ? HeyUpColor.accent : HeyUpColor.card)
                                .cornerRadius(11)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(vm.intervalMinutes == m ? HeyUpColor.accent : HeyUpColor.border))
                        }
                    }
                }

                group("STOP REMINDING AFTER") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach([2, 4, 6, 8], id: \.self) { h in
                            Button("\(h)h") { vm.sessionLengthHours = h }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(vm.sessionLengthHours == h ? .black : HeyUpColor.textMuted)
                                .frame(height: 38).frame(maxWidth: .infinity)
                                .background(vm.sessionLengthHours == h ? HeyUpColor.accent : HeyUpColor.card)
                                .cornerRadius(11)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(vm.sessionLengthHours == h ? HeyUpColor.accent : HeyUpColor.border))
                        }
                    }
                }

                Button {
                    vm.openSubExercise()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Break exercise").font(.system(size: 13, weight: .medium)).foregroundColor(HeyUpColor.textMuted)
                            Text(vm.exercise.displayName).font(.system(size: 18, weight: .semibold)).foregroundColor(HeyUpColor.textPrimary)
                        }
                        Spacer()
                        Text("›").font(.system(size: 28, weight: .heavy)).foregroundColor(HeyUpColor.accent)
                            .frame(width: 54, height: 54)
                            .background(HeyUpColor.border).clipShape(Circle())
                    }
                    .padding(16).background(HeyUpColor.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }

                group("REPS PER BREAK") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach([2, 5, 10, 15, 20, 30, 40, 50], id: \.self) { n in
                            Button("\(n)") { vm.repGoal = n }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(vm.repGoal == n ? .black : HeyUpColor.textSecondary)
                                .frame(height: 38).frame(maxWidth: .infinity)
                                .background(vm.repGoal == n ? HeyUpColor.accent : HeyUpColor.card)
                                .cornerRadius(11)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(vm.repGoal == n ? HeyUpColor.accent : HeyUpColor.border))
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

                group("NOTIFICATIONS") {
                    Toggle(isOn: $yorkshireVoiceCueEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Yorkshire voice cue")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Hear Mick say “Ey up!” when your movement break is ready.")
                                .font(.system(size: 12.5))
                                .foregroundColor(HeyUpColor.textMuted)
                        }
                    }
                    .tint(HeyUpColor.accent)
                    .padding(15)
                    .background(HeyUpColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }

#if DEBUG
                group("LOCAL TESTING") {
                    Button("Reset free-plan allowance") {
                        vm.resetFreePlanForTesting()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HeyUpColor.accent)

                    Button("Test notification sound in 5 seconds") {
                        NotificationManager.shared.scheduleVoiceCueTest()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HeyUpColor.accent)
                }
#endif

            }
            .padding(20)
            .padding(.bottom, 70)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Done") {
                vm.closeSettings()
            }
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(HeyUpColor.accent)
            .clipShape(Capsule())
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(HeyUpColor.background.opacity(0.96))
        }
    }

    private var exerciseSubScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button("‹ Back") { vm.closeSub() }
                        .buttonStyle(SecondaryPillStyle())
                    Text("Break Exercise").font(.system(size: 22, weight: .heavy))
                }
                VStack(spacing: 12) {
                    ForEach(ExerciseType.allCases) { ex in
                        exerciseCard(ex)
                    }
                }
                if vm.exercise == .both {
                    comboPicker
                }
            }
            .padding(20)
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 16.5, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
            content()
        }
    }

    private func exerciseCard(_ ex: ExerciseType) -> some View {
        let selected = vm.exercise == ex
        return Button {
            vm.selectExercise(ex)
            guard vm.screen == .settings else { return }
            if ex == .both {
                vm.comboUpperPicked = false
                vm.comboLowerPicked = false
            } else {
                vm.closeSub()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.displayName).font(.system(size: 16, weight: .semibold)).foregroundColor(HeyUpColor.textPrimary)
                    Text(exerciseDescription(ex)).font(.system(size: 12.5)).foregroundColor(HeyUpColor.textMuted)
                }
                Spacer()
                if (ex == .mix || ex == .both) && !vm.hasProAccess {
                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(HeyUpColor.accent)
                        .clipShape(Capsule())
                }
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
        case .wallPushup: return "Hands on the wall, easier on wrists"
        case .kneePushup: return "Push-ups from your knees — a step up from wall"
        case .floorPushup: return "Classic push-ups, camera to your side"
        case .mix: return "Rotates through all exercises, one per break"
        case .both: return "\(vm.comboUpper.displayName) then \(vm.comboLower.displayName)"
        }
    }

    private var comboPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Push-up style").font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint)
            FlowLayout(spacing: 6) {
                ForEach([ExerciseType.wallPushup, .kneePushup, .floorPushup]) { ex in
                    Button(ex.displayName) {
                        vm.comboUpper = ex
                        vm.comboUpperPicked = true
                        if vm.comboLowerPicked { vm.closeSub() }
                    }
                        .buttonStyle(ChipButtonStyle(selected: vm.comboUpper == ex))
                }
            }
            Text("Squat style").font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint).padding(.top, 4)
            FlowLayout(spacing: 6) {
                ForEach([ExerciseType.squats, .seatedSquat]) { ex in
                    Button(ex.displayName) {
                        vm.comboLower = ex
                        vm.comboLowerPicked = true
                        if vm.comboUpperPicked { vm.closeSub() }
                    }
                        .buttonStyle(ChipButtonStyle(selected: vm.comboLower == ex))
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.063, green: 0.075, blue: 0.035))
        .cornerRadius(14)
    }
}
