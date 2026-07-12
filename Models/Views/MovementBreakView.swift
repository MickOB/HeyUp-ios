import SwiftUI
import UIKit

struct MovementBreakView: View {
    @EnvironmentObject var vm: HeyUpViewModel

    var body: some View {
        VStack(spacing: 0) {
            if vm.cameraAccessDenied {
                cameraDeniedFallback
            } else {
                cameraContent
            }
        }
        .background(Color.black)
    }

    /// Shown when the user has denied camera access — previously this state
    /// left the screen blank with no way forward.
    private var cameraDeniedFallback: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Camera access needed")
                .font(.system(size: 22, weight: .heavy))
            Text("HeyUp needs your camera to count reps during a movement break. Nothing is recorded or uploaded.")
                .font(.system(size: 14)).foregroundColor(HeyUpColor.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: 280)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Skip this break") { vm.skipBreak() }
                .buttonStyle(SecondaryPillStyle())
            Spacer()
        }
        .padding(28)
        .foregroundColor(HeyUpColor.textPrimary)
    }

    private var cameraContent: some View {
        VStack(spacing: 0) {
            ZStack {
                CameraPreviewLayerView(session: vm.cameraManager.session)
                    .ignoresSafeArea(edges: .top)

                VStack {
                    VStack(spacing: 4) {
                        Text("MOVEMENT BREAK").font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.accent)
                        Text(vm.currentExercise.displayName).font(.system(size: 20, weight: .bold))
                        if vm.exercise == .both {
                            Text("Phase \(vm.breakPhase) of 2 · \(vm.breakPhase == 1 ? vm.comboUpper.displayName : vm.comboLower.displayName)")
                                .font(.system(size: 11, weight: .semibold)).foregroundColor(HeyUpColor.textMuted)
                        }
                    }
                    .padding(.top, 30)

                    if case .tooClose(let joint) = vm.framingStatus {
                        Text("Step back a little — I can't see your \(joint)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HeyUpColor.accentHover)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color(red: 0.114, green: 0.133, blue: 0.075))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HeyUpColor.border))
                            .padding(.top, 12)
                    } else if case .searching = vm.framingStatus {
                        Text("Finding you in frame…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HeyUpColor.textMuted)
                            .padding(.top, 12)
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text("\(vm.reps)").font(.system(size: 56, weight: .heavy)).monospacedDigit()
                            Text("/ \(vm.repGoal)").font(.system(size: 24, weight: .semibold)).foregroundColor(HeyUpColor.textFaint)
                        }
                        HStack(spacing: 7) {
                            ForEach(0..<vm.repGoal, id: \.self) { i in
                                Circle()
                                    .fill(i < vm.reps ? HeyUpColor.accent : HeyUpColor.border)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        Text(vm.repFeedback.isEmpty ? "Detecting body pose…" : vm.repFeedback)
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(HeyUpColor.textMuted)
                    }
                    .padding(.bottom, 26)
                }

                if vm.isResting {
                    VStack(spacing: 10) {
                        Text("Nice! Quick rest").font(.system(size: 14, weight: .semibold)).foregroundColor(HeyUpColor.textMuted)
                        Text("\(vm.restSecondsLeft)").font(.system(size: 52, weight: .heavy)).foregroundColor(HeyUpColor.accent).monospacedDigit()
                        Text("\(vm.comboLower.displayName) next").font(.system(size: 13)).foregroundColor(HeyUpColor.textFaint)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.94))
                }
            }
            .frame(maxHeight: .infinity)

            Button("Skip this break") { vm.skipBreak() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HeyUpColor.warn)
                .padding(.horizontal, 24).frame(height: 42)
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color(red: 0.227, green: 0.165, blue: 0.141)))
                .padding(.vertical, 20)
        }
    }
}
