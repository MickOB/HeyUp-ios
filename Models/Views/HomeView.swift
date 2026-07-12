import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    private let intervals = [20, 30, 45, 60, 90, 120]
    private let sessionHours = [2, 4, 6, 8]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("HeyUp").font(.system(size: 34, weight: .heavy))
                    Spacer()
                }
                Text(vm.profile.name.isEmpty
                     ? "Earn your screen time, one break at a time."
                     : "Ready when you are, \(vm.profile.name).")
                    .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted)

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

                sectionLabel("I'M SETTLING IN FOR")
                segmentedRow(SessionType.allCases.map(\.label), current: vm.sessionType.label) { label in
                    vm.sessionType = SessionType.allCases.first { $0.label == label } ?? .tv
                }

                sectionLabel("REMIND ME EVERY")
                gridRow(intervals.map { "\($0)m" }, current: "\(vm.intervalMinutes)m", columns: 3) { label in
                    vm.intervalMinutes = Int(label.dropLast()) ?? 30
                }

                sectionLabel("STOP REMINDING AFTER")
                gridRow(sessionHours.map { "\($0)h" }, current: "\(vm.sessionLengthHours)h", columns: 4) { label in
                    vm.sessionLengthHours = Int(label.dropLast()) ?? 4
                }
                Text("So you're not getting pinged at 2am.")
                    .font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint)

                sectionLabel("EXERCISE")
                Button {
                    vm.openSettings()
                } label: {
                    HStack {
                        Text(summaryText).font(.system(size: 14)).foregroundColor(HeyUpColor.textSecondary)
                        Spacer()
                        Text("Change ›").font(.system(size: 13, weight: .semibold)).foregroundColor(HeyUpColor.accent)
                    }
                    .padding(.horizontal, 16).frame(height: 50)
                    .background(HeyUpColor.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }

                sectionLabel("TODAY")
                HStack(spacing: 8) {
                    statTile(value: "\(vm.statsStore.today.completed)", label: "done")
                    statTile(value: "\(vm.statsStore.today.totalReps)", label: "reps")
                    statTile(value: "\(vm.statsStore.today.skipped)", label: "skipped")
                }

                Button("Start \(vm.intervalMinutes)-min block") { vm.startSessionFromHome() }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }
            .padding(20)
        }
    }

    private var summaryText: String {
        "\(vm.exercise.displayName) · \(vm.repGoal) reps · \(vm.sessionType.label)"
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(HeyUpColor.textMuted)
            Text(label).font(.system(size: 11.5)).foregroundColor(HeyUpColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(HeyUpColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }

    private func segmentedRow(_ options: [String], current: String, onSelect: @escaping (String) -> Void) -> some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { opt in
                Button(opt) { onSelect(opt) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(opt == current ? .black : HeyUpColor.textMuted)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(opt == current ? HeyUpColor.accent : Color.clear)
                    .cornerRadius(11)
            }
        }
        .padding(4)
        .background(HeyUpColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
    }

    private func gridRow(_ options: [String], current: String, columns: Int, onSelect: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(options, id: \.self) { opt in
                Button(opt) { onSelect(opt) }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(opt == current ? .black : HeyUpColor.textMuted)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(opt == current ? HeyUpColor.accent : HeyUpColor.card)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(opt == current ? HeyUpColor.accent : HeyUpColor.border))
            }
        }
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
