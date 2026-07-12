import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    HeyUpWordmark(size: 40)
                    Text(vm.profile.name.isEmpty
                         ? "Earn your screen time, one break at a time."
                         : "Ready when you are, \(vm.profile.name).")
                        .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted)
                }

                HStack(spacing: 8) {
                    if vm.statsStore.streak > 0 {
                        HStack(spacing: 6) {
                            Circle().fill(HeyUpColor.accent).frame(width: 8, height: 8)
                            Text("\(vm.statsStore.streak)-day streak").font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(HeyUpColor.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HeyUpColor.border))
                    }
                    Spacer()
                    Button("Settings") { vm.openSettings() }
                        .buttonStyle(SecondaryPillStyle())
                }
                .padding(.top, 6)

                sectionLabel("YOUR BREAK PLAN")
                Button {
                    vm.openSettings()
                } label: {
                    HStack {
                        Text(planSummaryText)
                            .font(.system(size: 16.5, weight: .semibold)).foregroundColor(HeyUpColor.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Change ›")
                            .font(.system(size: 15.5, weight: .heavy)).foregroundColor(.black)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(HeyUpColor.accent).cornerRadius(14)
                    }
                    .padding(16)
                    .background(HeyUpColor.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }

                sectionLabel("TODAY")
                HStack(spacing: 8) {
                    statTile(value: "\(vm.statsStore.today.completed)", label: "breaks done", color: HeyUpColor.accent)
                    statTile(value: "\(vm.statsStore.today.totalReps)", label: "total reps", color: HeyUpColor.textPrimary)
                    statTile(value: "\(vm.statsStore.today.skipped)", label: "skipped", color: HeyUpColor.textMuted)
                }

                Text("THIS WEEK · REPS PER DAY")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
                    .padding(.top, 4)
                weekChart

                HStack {
                    Spacer()
                    Button("See full history") { vm.openHistory() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(HeyUpColor.textMuted)
                        .underline()
                    Spacer()
                }

                Button("Start \(vm.intervalMinutes)-min block") { vm.startSessionFromHome() }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }
            .padding(20)
        }
    }

    private var planSummaryText: String {
        "\(vm.sessionType.label) · every \(vm.intervalMinutes) min · stop after \(vm.sessionLengthHours)h · \(vm.exercise.displayName)"
    }

    private var weekChart: some View {
        let week = vm.statsStore.weekHistory()
        let maxReps = max(1, week.map { $0.stats.totalReps }.max() ?? 1)
        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(week.indices, id: \.self) { i in
                    let entry = week[i]
                    let isToday = Calendar.current.isDateInToday(entry.date)
                    VStack(spacing: 5) {
                        Text(entry.stats.totalReps > 0 ? "\(entry.stats.totalReps)" : "")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isToday ? HeyUpColor.accent : HeyUpColor.textMuted)
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.stats.totalReps > 0 ? (isToday ? HeyUpColor.accent : HeyUpColor.textMuted.opacity(0.6)) : HeyUpColor.border)
                            .frame(height: entry.stats.totalReps > 0 ? 6 + 28 * CGFloat(entry.stats.totalReps) / CGFloat(maxReps) : 4)
                        Text(dayLetter(entry.date))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isToday ? HeyUpColor.accent : HeyUpColor.textFaint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(HeyUpColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }

    private func dayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // single-letter weekday
        return f.string(from: date)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
    }

    private func statTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11.5)).foregroundColor(HeyUpColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(HeyUpColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }
}

struct SecondaryPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(HeyUpColor.accent)
            .padding(.horizontal, 14).frame(height: 36)
            .background(HeyUpColor.card).cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HeyUpColor.border))
    }
}

/// The "Hey" + "Up" wordmark with the small upward caret over the "U" —
/// matches the app icon and the HTML prototype's branding exactly.
struct HeyUpWordmark: View {
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 0) {
            Text("Hey").font(.system(size: size, weight: .heavy)).foregroundColor(HeyUpColor.textPrimary)
            ZStack(alignment: .top) {
                Text("U").font(.system(size: size, weight: .heavy)).foregroundColor(HeyUpColor.accent)
                Caret()
                    .stroke(HeyUpColor.accent, style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.46, height: size * 0.28)
                    .offset(y: -size * 0.42)
            }
            Text("p").font(.system(size: size, weight: .heavy)).foregroundColor(HeyUpColor.accent)
        }
    }
}

/// Simple upward chevron (⌃) shape used above the wordmark's "U".
private struct Caret: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}
