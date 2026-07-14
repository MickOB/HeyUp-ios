import SwiftUI

struct GetReadyView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @State private var countdown = 8
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("GET READY").font(.system(size: 15, weight: .bold)).tracking(2).foregroundColor(HeyUpColor.accent)
            Text(vm.currentExercise.displayName).font(.system(size: 30, weight: .heavy))
            if vm.exercise == .both {
                Text("Phase 1 of 2 · \(vm.comboUpper.displayName)")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(HeyUpColor.textMuted)
            }
            VStack(spacing: 12) {
                ForEach(Array(vm.currentExercise.setupCues.enumerated()), id: \.offset) { i, cue in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(HeyUpColor.accent)
                            .frame(width: 26, height: 26)
                            .background(HeyUpColor.border).clipShape(Circle())
                        Text(cue).font(.system(size: 16)).foregroundColor(HeyUpColor.textSecondary).lineSpacing(3)
                        Spacer()
                    }
                    .padding(14)
                    .background(HeyUpColor.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HeyUpColor.border))
                }
            }
            .frame(maxWidth: 320)
            Text("\(countdown)")
                .font(.system(size: 56, weight: .heavy)).foregroundColor(HeyUpColor.accent).monospacedDigit()
            Text("Camera opens automatically").font(.system(size: 13.5)).foregroundColor(HeyUpColor.textFaint)
            Button("I'm ready — start now") {
                timer?.invalidate()
                vm.beginMovementBreak()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(HeyUpColor.accent)
            .padding(.horizontal, 20).frame(height: 46)
            .background(HeyUpColor.card).cornerRadius(23)
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(HeyUpColor.border))
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
