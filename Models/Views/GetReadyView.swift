import SwiftUI

struct GetReadyView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @State private var countdown = 8
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("GET READY").font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.accent)
            Text(vm.currentExercise.displayName).font(.system(size: 28, weight: .heavy))
            if vm.exercise == .both {
                Text("Phase 1 of 2 · \(vm.comboUpper.displayName)")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(HeyUpColor.textMuted)
            }
            VStack(spacing: 10) {
                ForEach(Array(vm.currentExercise.setupCues.enumerated()), id: \.offset) { i, cue in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.system(size: 12, weight: .bold)).foregroundColor(HeyUpColor.accent)
                            .frame(width: 22, height: 22)
                            .background(HeyUpColor.border).clipShape(Circle())
                        Text(cue).font(.system(size: 14)).foregroundColor(HeyUpColor.textSecondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(HeyUpColor.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }
            }
            .frame(maxWidth: 300)
            Text("\(countdown)")
                .font(.system(size: 52, weight: .heavy)).foregroundColor(HeyUpColor.accent).monospacedDigit()
            Text("Camera opens automatically").font(.system(size: 13)).foregroundColor(HeyUpColor.textFaint)
            Button("I'm ready — start now") {
                timer?.invalidate()
                vm.beginMovementBreak()
            }
            .buttonStyle(SecondaryPillStyle())
            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear { startCountdown() }
        .onDisappear { timer?.invalidate() }
    }

    private func startCountdown() {
        countdown = 8
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if countdown <= 1 {
                t.invalidate()
                vm.beginMovementBreak()
            } else {
                countdown -= 1
            }
        }
    }
}
