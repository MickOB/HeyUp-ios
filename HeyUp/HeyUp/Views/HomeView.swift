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
                        .font(.system(size: 16)).foregroundColor(HeyUpColor.textMuted)
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
                    Button(planBadgeText) {
                        if !vm.hasProAccess { vm.openPaywall() }
                    }
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(vm.hasProAccess ? .black : HeyUpColor.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(vm.hasProAccess ? HeyUpColor.accent : HeyUpColor.card)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(HeyUpColor.border))
                    Button("Settings") { vm.openSettings() }
                        .buttonStyle(SecondaryPillStyle())
                }
                .padding(.top, 6)

                Text("YOUR BREAK PLAN").font(.system(size: 13, weight: .bold)).foregroundColor(HeyUpColor.textFaint)
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
                    .padding(.top, 40)
                    .padding(.top, 6)
            }
            .padding(20)
        }
    }

    private var planSummaryText: String {
        "\(vm.sessionType.label) · every \(vm.intervalMinutes) min · stop after \(vm.sessionLengthHours)h · \(vm.exercise.displayName)"
    }

    private var planBadgeText: String {
        if vm.hasProAccess { return "PRO" }
        if !vm.introBreakCompleted { return "FREE INTRO" }
        return "FREE · \(vm.freeBreaksRemaining) left"
    }

    private static let exColors: [ExerciseType: Color] = [
        .squats: HeyUpColor.accent,
        .seatedSquat: Color(red: 0.61, green: 0.75, blue: 0.24),
        .wallPushup: Color(red: 0.46, green: 0.57, blue: 0.23),
        .kneePushup: Color(red: 0.34, green: 0.44, blue: 0.18),
        .floorPushup: Color(red: 0.25, green: 0.31, blue: 0.15)
    ]

    @State private var selectedDayIndex: Int? = nil

    private var weekChart: some View {
        let week = vm.statsStore.weekHistory()
        let maxReps = max(1, week.map { $0.stats.totalReps }.max() ?? 1)
        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(week.indices, id: \.self) { i in
                    let entry = week[i]
                    let isToday = Calendar.current.isDateInToday(entry.date)
                    Button {
                        selectedDayIndex = (selectedDayIndex == i) ? nil : i
                    } label: {
                        VStack(spacing: 5) {
                            Text(entry.stats.totalReps > 0 ? "\(entry.stats.totalReps)" : "")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isToday ? HeyUpColor.accent : HeyUpColor.textMuted)
                                .frame(height: 12)
                            VStack(spacing: 1) {
                                ForEach(barSegments(entry.stats, maxReps: maxReps), id: \.exercise) { seg in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Self.exColors[seg.exercise] ?? HeyUpColor.textMuted)
                                        .frame(height: seg.height)
                                }
                            }
                            .frame(width: 18)
                            .frame(height: 150, alignment: .bottom)
                            .opacity(entry.stats.totalReps > 0 ? 1 : 1)
                            .background(
                                entry.stats.totalReps == 0
                                    ? RoundedRectangle(cornerRadius: 3).fill(HeyUpColor.border).frame(width: 18, height: 4)
                                    : nil,
                                alignment: .bottom
                            )
                            Text(dayLetter(entry.date))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isToday ? HeyUpColor.accent : HeyUpColor.textFaint)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(dayDetailText(week: week))
                .font(.system(size: 12)).foregroundColor(HeyUpColor.textMuted)
                .multilineTextAlignment(.center)
                .frame(minHeight: 17)
            chartLegend(week: week)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(HeyUpColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }

    private struct BarSegment { let exercise: ExerciseType; let height: CGFloat }

    private func chartLegend(week: [(date: Date, stats: DailyStats)]) -> some View {
        let exercises = ExerciseType.countable.filter { exercise in
            week.contains { ($0.stats.repsByExercise[exercise.rawValue] ?? 0) > 0 }
        }
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], alignment: .leading, spacing: 6) {
            ForEach(exercises) { exercise in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Self.exColors[exercise] ?? HeyUpColor.textMuted)
                        .frame(width: 9, height: 9)
                    Text(exercise.displayName)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(HeyUpColor.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.top, exercises.isEmpty ? 0 : 4)
    }

    /// Splits a day's total bar height proportionally across the exercises
    /// that contributed reps, so a mixed day reads as a stacked bar —
    /// same idea as the prototype's stacked week chart.
    private func barSegments(_ stats: DailyStats, maxReps: Int) -> [BarSegment] {
        guard stats.totalReps > 0 else { return [] }
        let totalH = 8 + 130 * CGFloat(stats.totalReps) / CGFloat(maxReps)
        let contributing = ExerciseType.countable.filter { (stats.repsByExercise[$0.rawValue] ?? 0) > 0 }
        guard !contributing.isEmpty else {
            return [BarSegment(exercise: .squats, height: totalH)]
        }
        return contributing.map { ex in
            let share = CGFloat(stats.repsByExercise[ex.rawValue] ?? 0) / CGFloat(stats.totalReps)
            return BarSegment(exercise: ex, height: max(4, totalH * share))
        }
    }

    /// "Wed · 25 reps — 15 squats, 10 wall push-ups" for the selected day,
    /// or today's mix if none is selected.
    private func dayDetailText(week: [(date: Date, stats: DailyStats)]) -> String {
        let i = selectedDayIndex ?? week.indices.last(where: { Calendar.current.isDateInToday(week[$0].date) })
        guard let i, week.indices.contains(i) else { return "" }
        let entry = week[i]
        let f = DateFormatter(); f.dateFormat = "EEE"
        let label = f.string(from: entry.date)
        guard entry.stats.totalReps > 0 else { return "\(label) · no reps yet" }
        let parts = ExerciseType.countable.compactMap { ex -> String? in
            guard let reps = entry.stats.repsByExercise[ex.rawValue], reps > 0 else { return nil }
            return "\(reps) \(ex.displayName.lowercased())"
        }
        return "\(label) · \(entry.stats.totalReps) reps — \(parts.joined(separator: ", "))"
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
            Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 13)).foregroundColor(HeyUpColor.textMuted)
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
                    .stroke(HeyUpColor.accent, style: StrokeStyle(lineWidth: size * 0.085, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.29, height: size * 0.175)
                    .offset(y: -size * 0.2)
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
