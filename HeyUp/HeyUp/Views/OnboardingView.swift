import SwiftUI
import UIKit

/// 8-step onboarding: welcome → permissions primer → about you (sex, age,
/// name) → fitness level → how it works → notifications/camera perms →
/// accountability message → starting plan.
struct OnboardingView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @State private var step = 1
    @FocusState private var isNameFieldFocused: Bool
    private let totalSteps = 8

    var body: some View {
        VStack(spacing: 16) {
            // Steps 2 (About you) and 5 (Where did you hear) have enough
            // content that centering them left a large empty gap up top —
            // pin them to the top instead, matching the prototype.
            if step == 2 {
                ScrollView {
                    aboutYouStep
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
            } else if step == 5 {
                sourceStep
                    .padding(.top, 20)
                Spacer()
            } else {
                Spacer()
                Group {
                    switch step {
                    case 1: welcomeStep
                    case 3: fitnessStep
                    case 4: howItWorksStep
                    case 6: permissionsStep
                    case 7: accountabilityStep
                    default: startingPlanStep
                    }
                }
                Spacer()
            }
            VStack(spacing: 16) {
                HStack(spacing: 7) {
                    ForEach(1...totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == step ? HeyUpColor.accent : HeyUpColor.border)
                            .frame(width: 6, height: 6)
                    }
                }
                Button(step == totalSteps ? "Get started" : "Continue") {
                    isNameFieldFocused = false
                    if step == totalSteps {
                        vm.finishOnboarding()
                    } else {
                        step += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            }
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isNameFieldFocused = false
                }
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            HeyUpWordmark(size: 56)
            Text("Turns screen time into move time.")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(HeyUpColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            Text("Short movement breaks between watching TV, working from home, and everything in between. Your camera counts the reps.")
                .font(.system(size: 20))
                .foregroundColor(HeyUpColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
    }

    private var aboutYouStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("About you").font(.system(size: 28, weight: .heavy)).padding(.leading, 2)
            VStack(alignment: .leading, spacing: 10) {
                Text("Sex").font(.system(size: 28, weight: .semibold)).foregroundColor(HeyUpColor.textSecondary)
                wrapButtons(["Female", "Male", "Prefer not to say"], selection: $vm.profile.sex)
            }
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("Age range — so we suggest the right pace")
                listButtons(AgeRange.allCases.map(\.rawValue), selection: Binding(
                    get: { vm.profile.ageRange?.rawValue ?? "" },
                    set: { vm.profile.ageRange = AgeRange(rawValue: $0) }
                ))
            }
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("What should we call you?")
                TextField("First name (optional)", text: $vm.profile.name)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFieldFocused = false
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(HeyUpColor.card)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
            }
        }
    }

    private var fitnessStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How's your fitness right now?")
                .font(.system(size: 32, weight: .heavy))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Honest answer — we'll pick the right starting point.")
                .font(.system(size: 15)).foregroundColor(HeyUpColor.textSecondary)
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
            Text("A SIMPLE WAY FORWARD").font(.system(size: 17, weight: .bold)).foregroundColor(HeyUpColor.accent)
            Text("A stronger future can start small.")
                .font(.system(size: 32, weight: .heavy)).lineSpacing(4)
            Text("You don't need to redesign your life. HeyUp helps you build a repeatable strength habit inside the day you already have.")
                .font(.system(size: 15.5)).foregroundColor(HeyUpColor.textSecondary)
            VStack(alignment: .leading, spacing: 0) {
                howStep(1, "Choose a TV time, Home office, or Daily life block.")
                howStep(2, "When time is up, take a short movement break.")
                howStep(3, "Your camera counts each rep privately, on your device.")
            }
            .padding(.top, 4)
            Text("Small sessions. Clear guidance. Consistency you can actually keep.")
                .font(.system(size: 15.5)).foregroundColor(HeyUpColor.textSecondary)
                .padding(.top, 16)
                .overlay(Rectangle().frame(height: 1).foregroundColor(HeyUpColor.border), alignment: .top)
        }
    }

    private func howStep(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(n)").font(.system(size: 16, weight: .bold)).monospacedDigit().foregroundColor(HeyUpColor.textFaint).frame(width: 16, alignment: .leading)
            Text(text).font(.system(size: 16)).foregroundColor(HeyUpColor.textPrimary).lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(Rectangle().frame(height: 1).foregroundColor(HeyUpColor.border), alignment: .top)
    }

    private var sourceStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Where did you hear about us?").font(.system(size: 28, weight: .heavy)).padding(.leading, 2)
            ScrollView {
                sourceListButtons(["TikTok", "Instagram", "YouTube", "Facebook", "X (Twitter)", "Reddit", "Friend or family", "App Store", "Other"], selection: $vm.profile.source)
            }
            Text("Optional — helps us know where to say hi.")
                .font(.system(size: 12)).foregroundColor(HeyUpColor.textFaint).padding(.leading, 2)
        }
    }

    private static let sourceBrandColors: [String: Color] = [
        "TikTok": Color(red: 0.933, green: 0.114, blue: 0.322),
        "Instagram": Color(red: 0.757, green: 0.208, blue: 0.518),
        "YouTube": Color(red: 1.0, green: 0.0, blue: 0.0),
        "Facebook": Color(red: 0.094, green: 0.467, blue: 0.949),
        "X (Twitter)": Color(red: 0.961, green: 0.961, blue: 0.961),
        "Reddit": Color(red: 1.0, green: 0.271, blue: 0.0),
        "Friend or family": HeyUpColor.textMuted,
        "App Store": Color(red: 0.039, green: 0.518, blue: 1.0),
        "Other": Color(red: 0.353, green: 0.388, blue: 0.314)
    ]

    /// Same full-width listed row as `listButtons`, with a small colored
    /// initial badge per option (stand-in for real brand logos — swap in
    /// official assets if/when available).
    private func sourceListButtons(_ options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                Button {
                    selection.wrappedValue = opt
                } label: {
                    HStack(spacing: 12) {
                        Text(String(opt.prefix(1)))
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Self.sourceBrandColors[opt] ?? HeyUpColor.textMuted)
                            .cornerRadius(8)
                        Text(opt).font(.system(size: 15, weight: .medium))
                        Spacer()
                        if selection.wrappedValue == opt {
                            Text("✓").font(.system(size: 15, weight: .bold))
                        }
                    }
                    .foregroundColor(selection.wrappedValue == opt ? .black : HeyUpColor.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 54).frame(maxWidth: .infinity)
                    .background(selection.wrappedValue == opt ? HeyUpColor.accent : HeyUpColor.card)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(selection.wrappedValue == opt ? HeyUpColor.accent : HeyUpColor.border))
                }
            }
        }
    }

    @State private var notifOk = false
    @State private var camOk = false

    private var permissionsStep: some View {
        VStack(spacing: 18) {
            Text("Two quick permissions").font(.system(size: 24, weight: .heavy))
            Text("HeyUp needs your camera to count reps, and notifications to remind you when a break is ready.")
                .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted).multilineTextAlignment(.center)
            permissionRow(title: "Notifications", subtitle: "So we can tap you when it's break time", granted: notifOk) {
                // If iOS already has a decision on file (granted or denied),
                // requesting again shows no system prompt at all — it just
                // silently returns the existing answer. Route to Settings
                // in that case so tapping "Allow" always does something.
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        if settings.authorizationStatus == .notDetermined {
                            NotificationManager.shared.requestPermission { granted in notifOk = granted }
                        } else if settings.authorizationStatus == .authorized {
                            notifOk = true
                        } else {
                            openSettings()
                        }
                    }
                }
            }
            permissionRow(title: "Camera", subtitle: "To count your reps — on-device only", granted: camOk) {
                vm.cameraManager.requestAccess { granted in
                    camOk = granted
                    if !granted { openSettings() }
                }
            }
        }
    }

    private func permissionRow(title: String, subtitle: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 12.5)).foregroundColor(HeyUpColor.textMuted)
            }
            Spacer()
            Button(granted ? "Allowed ✓" : "Allow", action: action)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(granted ? HeyUpColor.accent : .black)
                .padding(.horizontal, 16).frame(height: 38)
                .background(granted ? HeyUpColor.card : HeyUpColor.accent)
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(granted ? HeyUpColor.border : .clear))
                .cornerRadius(19)
        }
        .padding(15)
        .background(HeyUpColor.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var accountabilityStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WHY STRENGTH MATTERS")
                .font(.system(size: 13, weight: .bold)).foregroundColor(HeyUpColor.accent)
                .tracking(2)
            Text("Strength is more than fitness.")
                .font(.system(size: 30, weight: .heavy)).lineSpacing(2)
            Text("It supports the everyday abilities that keep you independent.")
                .font(.system(size: 16)).foregroundColor(HeyUpColor.textSecondary).lineSpacing(3)
            Divider().background(HeyUpColor.border).padding(.vertical, 4)
            strengthRow(icon: "🧍", title: "Get up with confidence", subtitle: "From a chair, the floor, or the garden.")
            Divider().background(HeyUpColor.border)
            strengthRow(icon: "🛍️", title: "Carry everyday life", subtitle: "Groceries, luggage, and the things that matter.")
            Divider().background(HeyUpColor.border)
            strengthRow(icon: "🚶", title: "Keep going places", subtitle: "Support mobility, balance, and daily function.")
            Divider().background(HeyUpColor.border).padding(.bottom, 2)
            Text("Regular activity can help slow age-related strength decline, and it is never too late — or too early — to begin.")
                .font(.system(size: 14.5)).foregroundColor(HeyUpColor.textMuted).lineSpacing(3)
            Text("Show up today.\nYour future self will thank you.")
                .font(.system(size: 20, weight: .heavy)).foregroundColor(HeyUpColor.accent)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func strengthRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(icon).font(.system(size: 24)).foregroundColor(HeyUpColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17, weight: .bold))
                Text(subtitle).font(.system(size: 14.5)).foregroundColor(HeyUpColor.textSecondary)
            }
        }
    }

    private var startingPlanStep: some View {
        let plan = vm.profile.recommendedPlan()
        let who = vm.profile.name.isEmpty ? "We" : "\(vm.profile.name), we"
        return VStack(spacing: 18) {
            Text("YOUR STARTING PLAN")
                .font(.system(size: 17, weight: .bold))
                .tracking(2)
                .foregroundColor(HeyUpColor.accent)
            Text("\(plan.push.displayName) + \(plan.legs.displayName)")
                .font(.system(size: 31, weight: .heavy)).lineSpacing(4)
                .multilineTextAlignment(.center).frame(maxWidth: 290)
            Text("\(who)'d start you with \(plan.reps) reps per break — enough to begin building consistency without making the first step intimidating.")
                .font(.system(size: 16)).foregroundColor(HeyUpColor.textSecondary).lineSpacing(4)
                .multilineTextAlignment(.center).frame(maxWidth: 290)
            VStack(alignment: .center, spacing: 10) {
                Text("Start where you are").font(.system(size: 16, weight: .bold)).foregroundColor(HeyUpColor.textPrimary)
                Text("Wall → knee → floor push-ups\nSeated → full squats")
                    .font(.system(size: 15)).foregroundColor(HeyUpColor.textSecondary).lineSpacing(4)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 280, alignment: .center)
            .padding(.top, 20)
            .overlay(Rectangle().frame(height: 1).foregroundColor(HeyUpColor.border), alignment: .top)
            Text("As it gets easier, HeyUp grows with you.")
                .font(.system(size: 14.5)).foregroundColor(HeyUpColor.textFaint).frame(maxWidth: 280)
                .padding(.top, 20)
                .overlay(Rectangle().frame(height: 1).foregroundColor(HeyUpColor.border), alignment: .top)
            Text("Start slow, and check with a doctor first if you have a health condition.")
                .font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint).lineSpacing(2).frame(maxWidth: 280)
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

    /// A vertical list of full-width rows — used where options should read
    /// top-to-bottom rather than wrap-flow into a cramped block (e.g. the 6
    /// age ranges, which looked squashed together as chips).
    private func listButtons(_ options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                Button {
                    selection.wrappedValue = opt
                } label: {
                    HStack {
                        Text(opt).font(.system(size: 15, weight: .medium))
                        Spacer()
                        if selection.wrappedValue == opt {
                            Text("✓").font(.system(size: 15, weight: .bold))
                        }
                    }
                    .foregroundColor(selection.wrappedValue == opt ? .black : HeyUpColor.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 48).frame(maxWidth: .infinity)
                    .background(selection.wrappedValue == opt ? HeyUpColor.accent : HeyUpColor.card)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(selection.wrappedValue == opt ? HeyUpColor.accent : HeyUpColor.border))
                }
            }
        }
    }

    private func optionCard(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 21, weight: .semibold)).foregroundColor(HeyUpColor.textPrimary)
                    Text(subtitle).font(.system(size: 16)).foregroundColor(HeyUpColor.textMuted)
                }
                Spacer()
                Circle()
                    .strokeBorder(selected ? HeyUpColor.accent : HeyUpColor.border, lineWidth: selected ? 6 : 2)
                    .background(Circle().fill(HeyUpColor.background))
                    .frame(width: 20, height: 20)
            }
            .padding(20)
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
            .padding(.horizontal, 28)
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
            .padding(.horizontal, 20)
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
