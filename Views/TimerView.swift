import SwiftUI

struct TimerView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    private var minutes: Int { vm.secondsLeft / 60 }
    private var seconds: Int { vm.secondsLeft % 60 }
    private var progress: Double {
        vm.totalSeconds == 0 ? 0 : 1 - Double(vm.secondsLeft) / Double(vm.totalSeconds)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 20) {
                Spacer()
                Text(vm.isPaused ? "PAUSED" : vm.sessionType.timerHeading)
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(HeyUpColor.accent)
                Text(String(format: "%d:%02d", minutes, seconds))
                    .font(.system(size: 64, weight: .heavy)).monospacedDigit()
                RoundedRectangle(cornerRadius: 3)
                    .fill(HeyUpColor.border)
                    .frame(height: 6)
                    .overlay(
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(HeyUpColor.accent)
                                .frame(width: geo.size.width * progress)
                        }, alignment: .leading
                    )
                    .padding(.horizontal, 40)
                Text(vm.sessionType.waitingCopy)
                    .font(.system(size: 13.5)).foregroundColor(HeyUpColor.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
                Spacer()
                HStack(spacing: 14) {
                    Button(vm.isPaused ? "Resume" : "Pause") { vm.togglePause() }
                        .buttonStyle(SecondaryPillStyle())
                    Button("Move now") { vm.skipToBreakNow() }
                        .buttonStyle(SecondaryPillStyle())
                    Button("Home") { vm.goHome() }
                        .buttonStyle(SecondaryPillStyle())
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)

            if vm.showOneMinuteWarning {
                oneMinuteBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: vm.showOneMinuteWarning)
            }
        }
    }

    private var oneMinuteBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Hey").font(.system(size: 15, weight: .heavy)) + Text("Up").font(.system(size: 15, weight: .heavy)).foregroundColor(HeyUpColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("HeyUp").font(.system(size: 13.5, weight: .bold))
                    Spacer()
                    Text("now").font(.system(size: 11.5)).foregroundColor(HeyUpColor.textFaint)
                }
                Text(vm.sessionType.oneMinuteWarning())
                    .font(.system(size: 13)).foregroundColor(HeyUpColor.textSecondary)
            }
        }
        .padding(14)
        .background(HeyUpColor.card.opacity(0.96))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HeyUpColor.border))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
}
