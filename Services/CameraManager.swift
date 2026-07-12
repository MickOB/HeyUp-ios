import Foundation
import AVFoundation
import UIKit
import Combine
/// Owns the AVCaptureSession that feeds frames to Vision. Runs the capture
/// pipeline on a dedicated background queue; publishes each frame's Vision
/// request results back to whoever set `onBodyPose`.
final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.heyup.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var poseCounter: PoseCounter?

    @Published var isAuthorized = false

    func requestAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted)
                }
            }
        default:
            isAuthorized = false
            completion(false)
        }
    }

    /// Wires up the front camera and hands each frame to `counter`.
    func startSession(counter: PoseCounter) {
        self.poseCounter = counter
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.configureSessionIfNeeded()
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private var configured = false
    private func configureSessionIfNeeded() {
        guard !configured else { return }
        configured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        // Mirror + rotate for a natural front-camera preview. `videoRotationAngle`
        // is iOS 17+; if your deployment target is lower, replace this with
        // `connection.videoOrientation = .portrait` (the pre-iOS17 API) instead.
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            connection.isVideoMirrored = true
        }
        session.commitConfiguration()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // The front camera's raw buffer is NOT upright — it comes out of the
        // sensor in landscape. We lock the preview/UI to portrait, so the
        // buffer Vision sees must be told it's rotated + mirrored accordingly.
        // Getting this wrong is the single biggest cause of bad pose
        // detection: Vision would be reading a sideways image and every
        // joint angle this app computes would be meaningless.
        poseCounter?.process(pixelBuffer: pixelBuffer, orientation: .leftMirrored)
    }
}
