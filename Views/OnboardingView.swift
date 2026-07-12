import SwiftUI

/// 8-step onboarding: welcome → permissions primer → about you (sex, age,
/// name) → fitness level → how it works → notifications/camera perms →
/// accountability message → starting plan.
struct OnboardingView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @State private var step = 1
    private let totalSteps = 8

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Group {
                switch step {
                case 1: welcomeStep
                case 2: aboutYouStep
                case 3: fitnessStep
                case 4: howItWorksStep
                case 5: sourceStep
                case 6: permissionsStep
                case 7: accountabilityStep
                default: startingPlanStep
                }
            }
            Spacer()
            VStack(spacing: 16) {
                HStack(spacing: 7) {
                    ForEach(1...totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == step ? HeyUpColor.accent : HeyUpColor.border)
                            .frame(width: 6, height: 6)
                    }
                }
                Button(step == totalSteps ? "Get started" : "Continue") {
                    if step == totalSteps {
                        vm.finishOnboarding()
                    } else {
                        step += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 210)
            }
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            HeyUpWordmark(size: 44)
            Text("Short movement breaks between the TV time and work you already do.")
                .font(.system(size: 15))
                .foregroundColor(HeyUpColor.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var aboutYouStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About you").font(.system(size: 24, weight: .heavy))
            fieldLabel("Sex")
            wrapButtons(["Female", "Male", "Prefer not to say"], selection: $vm.profile.sex)
            fieldLabel("Age range — so we suggest the right pace")
            wrapButtons(AgeRange.allCases.map(\.rawValue), selection: Binding(
                get: { vm.profile.ageRange?.rawValue ?? "" },
                set: { vm.profile.ageRange = AgeRange(rawValue: $0) }
            ))
            fieldLabel("What should we call you?")
            TextField("First name (optional)", text: $vm.profile.name)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(HeyUpColor.card)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
        }
    }

    private var fitnessStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How's your fitness right now?").font(.system(size: 24, weight: .heavy))
            Text("Honest answer — we'll pick the right starting point.")
                .font(.system(size: 13)).foregroundColor(HeyUpColor.textMuted)
            VStack(spacing: 8) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    optionCard(
                        title: level.rawValue,
                        subtitle: fitnessDescription(level),
                        selected: vm.profile.fitness == level
                    ) { vm.profile.fitness = level }
                }
            }
        }
    }

    private func fitnessDescription(_ level: FitnessLevel) -> String {
        switch level {
        case .gettingStarted: return "It's been a while since I exercised"
        case .moveABit: return "Walks, occasional exercise"
        case .prettyActive: return "Push-ups don't scare me"
        case .veryActive: return "I train or exercise most days"
        }
    }

    private var howItWorksStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works").font(.system(size: 24, weight: .heavy))
            bullet("Pick how often you want a nudge, and what to do when it comes.")
            bullet("When the timer ends, your camera opens and counts your reps.")
            bullet("Finish the set and you've earned your next block.")
        }
    }

    private var sourceStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Where did you hear about us?").font(.system(size: 24, weight: .heavy))
            wrapButtons(["Instagram", "TikTok", "X / Twitter", "Friend", "App Store", "Other"], selection: $vm.profile.source)
        }
    }

    private var permissionsStep: some View {
        VStack(spacing: 18) {
            Text("Two quick permissions").font(.system(size: 24, weight: .heavy))
            Text("HeyUp needs your camera to count reps, and notifications to remind you when a break is ready.")
                .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted).multilineTextAlignment(.center)
            Button("Allow camera & notifications") {
                NotificationManager.shared.requestPermission { _ in }
                vm.cameraManager.requestAccess { _ in }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var accountabilityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("30 is when it starts.").font(.system(size: 22, weight: .heavy))
            Text("Muscle loss. Quietly. Every year.").foregroundColor(HeyUpColor.textSecondary)
            Text("Left unchecked, it affects your mobility, balance and independence later in life.").foregroundColor(HeyUpColor.textSecondary)
            Text("You don't need a gym. You need a few minutes and a decision.").foregroundColor(HeyUpColor.textSecondary)
            Divider().background(HeyUpColor.border)
            Text("Most people don't need more information.\nThey need accountability.").foregroundColor(HeyUpColor.textMuted)
            Text("Show up today.\nYour future self will thank you.")
                .font(.system(size: 19, weight: .heavy)).foregroundColor(HeyUpColor.accent)
        }
    }

    private var startingPlanStep: some View {
        let plan = vm.profile.recommendedPlan()
        let who = vm.profile.name.isEmpty ? "We'd" : "\(vm.profile.name), we'd"
        return VStack(spacing: 16) {
            Text("YOUR STARTING PLAN").font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.accent)
            Text("\(plan.push.displayName) + \(plan.legs.displayName)")
                .font(.system(size: 26, weight: .heavy)).multilineTextAlignment(.center)
            Text("\(who) start you with \(plan.push.displayName.lowercased()) and \(plan.legs.displayName.lowercased()) — \(plan.reps) reps per break.")
                .font(.system(size: 14.5)).foregroundColor(HeyUpColor.textSecondary).multilineTextAlignment(.center)
            Text("As it gets easy, work up the ladder: wall → knee → floor push-ups, and seated squat → full squats.")
                .font(.system(size: 12.5)).foregroundColor(HeyUpColor.textFaint).multilineTextAlignment(.center)
            Text("Start slow and stop if anything hurts. If you have a health condition or haven't exercised in a long while, a quick check-in with your doctor first is a good idea.")
                .font(.system(size: 12)).foregroundColor(HeyUpColor.textMuted)
                .padding(12)
                .background(HeyUpColor.card)
                .cornerRadius(12)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Small helpers

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 13)).foregroundColor(HeyUpColor.textMuted)
    }

    private func bullet(_ text: String) -> some View {
        Text(text).font(.system(size: 14.5)).foregroundColor(HeyUpColor.textSecondary)
    }

    private func wrapButtons(_ options: [String], selection: Binding<String>) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                Button(opt) { selection.wrappedValue = opt }
                    .buttonStyle(ChipButtonStyle(selected: selection.wrappedValue == opt))
            }
        }
    }

    private func optionCard(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(HeyUpColor.textPrimary)
                    Text(subtitle).font(.system(size: 12.5)).foregroundColor(HeyUpColor.textMuted)
                }
                Spacer()
                Circle()
                    .strokeBorder(selected ? HeyUpColor.accent : HeyUpColor.border, lineWidth: selected ? 6 : 2)
                    .background(Circle().fill(HeyUpColor.background))
                    .frame(width: 20, height: 20)
            }
            .padding(16)
            .background(HeyUpColor.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? HeyUpColor.accent : HeyUpColor.border, lineWidth: selected ? 1.5 : 1))
        }
    }
}

// MARK: - Reusable styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .frame(height: 52)
            .background(configuration.isPressed ? HeyUpColor.accentHover : HeyUpColor.accent)
            .cornerRadius(26)
    }
}

struct ChipButtonStyle: ButtonStyle {
    let selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(selected ? .black : HeyUpColor.textSecondary)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(selected ? HeyUpColor.accent : HeyUpColor.card)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? HeyUpColor.accent : HeyUpColor.border))
    }
}

/// Minimal wrapping HStack for chip groups (SwiftUI has no built-in flow layout pre-iOS16 Layout protocol version here).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
