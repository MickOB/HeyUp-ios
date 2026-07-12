import SwiftUI

/// Week / Month / Year rollup of past activity — an ongoing tabulation that
/// naturally builds up over time as StatsStore accumulates dated entries.
struct HistoryView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @State private var range: HistoryRange = .week

    private static let exerciseColors: [String: Color] = [
        "squats": HeyUpColor.accent,
        "seatedSquat": Color(red: 0.608, green: 0.753, blue: 0.243),
        "wallPushup": Color(red: 0.459, green: 0.573, blue: 0.227),
        "kneePushup": Color(red: 0.341, green: 0.435, blue: 0.180),
        "floorPushup": Color(red: 0.255, green: 0.310, blue: 0.149)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Button("‹ Back") { vm.closeHistory() }
                        .buttonStyle(SecondaryPillStyle())
                    Text("History").font(.system(size: 22, weight: .heavy))
                }

                HStack(spacing: 4) {
                    ForEach(HistoryRange.allCases) { r in
                        Button(r.label) { range = r }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(r == range ? .black : HeyUpColor.textMuted)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(r == range ? HeyUpColor.accent : Color.clear)
                            .cornerRadius(11)
                    }
                }
                .padding(4)
                .background(HeyUpColor.card).cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))

                let buckets = vm.historyBuckets(range: range)

                group(barsHeading) {
                    barsChart(buckets)
                    legend
                }

                group(totalsHeading) {
                    VStack(spacing: 8) {
                        ForEach(totalsByExercise(buckets), id: \.key) { entry in
                            HStack {
                                HStack(spacing: 10) {
                                    Circle().fill(Self.exerciseColors[entry.key] ?? HeyUpColor.textMuted).frame(width: 10, height: 10)
                                    Text(displayName(entry.key)).font(.system(size: 14)).foregroundColor(HeyUpColor.textSecondary)
                                }
                                Spacer()
                                Text("\(entry.value) reps").font(.system(size: 14, weight: .bold)).foregroundColor(HeyUpColor.textPrimary)
                            }
                            .padding(.horizontal, 16).frame(height: 46)
                            .background(HeyUpColor.card).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                        }
                    }
                }

                group(summaryHeading) {
                    HStack(spacing: 8) {
                        statTile(value: "\(buckets.reduce(0) { $0 + ($1.totalReps > 0 ? 1 : 0) })", label: range == .week ? "active days" : "active \(range == .month ? "weeks" : "months")", color: HeyUpColor.textMuted)
                        statTile(value: "\(buckets.reduce(0) { $0 + $1.totalReps })", label: "total reps", color: HeyUpColor.textPrimary)
                        statTile(value: bestLabel(buckets), label: bestCaption, color: HeyUpColor.textMuted)
                    }
                }
            }
            .padding(20)
        }
    }

    private var barsHeading: String {
        switch range {
        case .week: return "LAST 7 DAYS · BY EXERCISE"
        case .month: return "LAST 5 WEEKS · BY EXERCISE"
        case .year: return "LAST 12 MONTHS · BY EXERCISE"
        }
    }
    private var totalsHeading: String {
        switch range {
        case .week: return "TOTALS THIS WEEK"
        case .month: return "TOTALS THIS MONTH"
        case .year: return "TOTALS THIS YEAR"
        }
    }
    private var summaryHeading: String {
        switch range {
        case .week: return "SEVEN-DAY SUMMARY"
        case .month: return "MONTHLY SUMMARY"
        case .year: return "YEARLY SUMMARY"
        }
    }
    private var bestCaption: String {
        switch range {
        case .week: return "best day"
        case .month: return "best week"
        case .year: return "best month"
        }
    }

    private func bestLabel(_ buckets: [HeyUpViewModel.HistoryBucket]) -> String {
        guard let best = buckets.max(by: { $0.totalReps < $1.totalReps }), best.totalReps > 0 else { return "—" }
        return best.label
    }

    private func totalsByExercise(_ buckets: [HeyUpViewModel.HistoryBucket]) -> [(key: String, value: Int)] {
        var totals: [String: Int] = [:]
        for b in buckets { for (k, v) in b.repsByExercise { totals[k, default: 0] += v } }
        return totals.filter { $0.value > 0 }.sorted { $0.value > $1.value }
    }

    private func displayName(_ key: String) -> String {
        ExerciseType(rawValue: key)?.displayName ?? key
    }

    private func barsChart(_ buckets: [HeyUpViewModel.HistoryBucket]) -> some View {
        let maxReps = max(1, buckets.map(\.totalReps).max() ?? 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(buckets.indices, id: \.self) { i in
                let b = buckets[i]
                VStack(spacing: 5) {
                    Text(b.totalReps > 0 ? "\(b.totalReps)" : "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(b.isCurrent ? HeyUpColor.accent : HeyUpColor.textMuted)
                        .frame(height: 12)
                    stackedBar(b, maxReps: maxReps)
                    Text(b.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(b.isCurrent ? HeyUpColor.accent : HeyUpColor.textFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 90, alignment: .bottom)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(HeyUpColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }

    private func stackedBar(_ b: HeyUpViewModel.HistoryBucket, maxReps: Int) -> some View {
        let totalHeight: CGFloat = b.totalReps > 0 ? 10 + 50 * CGFloat(b.totalReps) / CGFloat(maxReps) : 4
        return VStack(spacing: 1) {
            if b.totalReps > 0 {
                ForEach(Array(b.repsByExercise.keys.sorted()), id: \.self) { key in
                    if let reps = b.repsByExercise[key], reps > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Self.exerciseColors[key] ?? HeyUpColor.textMuted)
                            .frame(height: max(3, totalHeight * CGFloat(reps) / CGFloat(b.totalReps)))
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 2).fill(HeyUpColor.border).frame(height: 4)
            }
        }
        .frame(width: 18)
    }

    private var legend: some View {
        HStack(spacing: 10) {
            ForEach(["squats", "seatedSquat", "wallPushup", "kneePushup", "floorPushup"], id: \.self) { key in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(Self.exerciseColors[key] ?? HeyUpColor.textMuted).frame(width: 8, height: 8)
                    Text(shortName(key)).font(.system(size: 10.5)).foregroundColor(HeyUpColor.textMuted)
                }
            }
        }
    }

    private func shortName(_ key: String) -> String {
        switch key {
        case "squats": return "Squats"
        case "seatedSquat": return "Seated"
        case "wallPushup": return "Wall"
        case "kneePushup": return "Knee"
        case "floorPushup": return "Floor"
        default: return key
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
            content()
        }
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
