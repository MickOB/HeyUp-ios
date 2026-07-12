import Foundation
import Vision
import CoreGraphics

/// Live framing feedback for the movement-break screen — tells the user how
/// to reposition so Vision can actually see the joints it needs.
enum FramingStatus: Equatable {
    case searching                       // no usable body detected yet
    case tooClose(missingJoint: String)  // a needed joint is off-screen/low-confidence
    case good                            // all needed joints visible with decent confidence
}

/// The five stages of one rep. This is deliberately explicit (rather than
/// just "up"/"down") so the movement-break screen can coach the user through
/// the rep in real time instead of just showing a number.
enum RepPhase {
    case standing   // fully extended — the resting/starting position
    case lowering   // moving down, not deep enough yet
    case bottom     // deep enough — good depth reached
    case rising     // moving back up from the bottom, not extended yet
    case completed  // just crossed back to fully extended — one rep just counted
}

/// Counts reps for ONE exercise at a time by tracking a single joint angle
/// (from Vision's body-pose landmarks) through an explicit 5-phase state
/// machine, and reports live coaching text for each phase.
///
/// WHY ANGLES INSTEAD OF RAW POSITION:
/// Raw joint Y-coordinates depend on how far the phone is from the user and
/// where it's propped — the same squat looks like a "20% drop" from one
/// camera position and a "35% drop" from another. A JOINT ANGLE (e.g. the
/// knee angle formed by hip→knee→ankle) doesn't care about distance or
/// camera height: a fully bent knee reads ~80-100° whether the phone is near
/// or far. That's why:
///   - Squats AND the seated squat both use the KNEE ANGLE (hip-knee-ankle,
///     using Vision's `.rightHip`/`.rightKnee`/`.rightAnkle` landmarks, or
///     the left-side equivalents — see `evaluateBestSide` below). They're
///     biomechanically the same movement (standing fully extends the knee;
///     sitting/squatting bends it), so one metric covers both.
///   - All three push-up variants (wall/knee/floor) use the ELBOW ANGLE
///     (shoulder-elbow-wrist). Arm bend looks the same whether you're
///     vertical against a wall or horizontal on the floor.
///
/// THE STATE MACHINE (see `advancePhase` for the actual transitions):
/// standing → lowering → bottom → rising → completed → back to standing.
/// A rep can only be counted after genuinely passing through `bottom` —
/// that, plus a minimum-time debounce, is what prevents double-counting a
/// single real repetition from a noisy or fast frame.
///
/// RELIABILITY NOTES:
/// - We check BOTH the left and right side each frame and use whichever is
///   more confidently visible, so a user angled slightly away from camera
///   (or with one side in shadow) doesn't silently stop counting.
/// - A phase transition must hold for `framesToConfirm` consecutive frames
///   before it's trusted — filters single-frame jitter, which is common in
///   dim rooms where Vision's confidence is generally lower.
final class PoseCounter {
    private let metric: RepMetric
    private let onRepCounted: () -> Void
    private let onFramingChanged: (FramingStatus) -> Void
    private let onFeedbackChanged: (String) -> Void

    /// Angle (degrees) ABOVE which the joint counts as fully extended
    /// (standing tall / arms straight) — the "standing" and "completed" zone.
    /// Set per EXERCISE (not just per metric) — see `thresholds(for:)` below —
    /// because different variants of the "same" movement have different
    /// realistic ranges of motion (a wall push-up bends far less than a
    /// floor push-up; a seated squat often doesn't fully straighten the way
    /// a standing squat does, especially for less mobile users).
    private let standThreshold: CGFloat
    /// Angle BELOW which the joint counts as deep enough (a real squat / a
    /// real bent-arm push-up) — the "bottom" zone. Also exercise-specific.
    private let bottomThreshold: CGFloat

    private var phase: RepPhase = .standing
    /// Frames the current CANDIDATE phase has held, before we trust it enough
    /// to actually switch `phase`. Resets whenever the candidate changes.
    private var pendingPhase: RepPhase?
    private var pendingPhaseFrames = 0
    private let framesToConfirm = 2

    /// Minimum time between counted reps — a second guard against
    /// double-counting on top of the phase machine itself (belt and
    /// suspenders: a real rep is rarely faster than this even done briskly).
    private let minRepInterval: TimeInterval = 0.5
    private var lastRepTime: Date = .distantPast

    /// Vision considers a joint "visible" above this confidence. Below it we
    /// treat the joint as missing for framing-feedback purposes.
    private let confidenceThreshold: VNConfidence = 0.3

    private let sequenceHandler = VNSequenceRequestHandler()

    init(
        exercise: ExerciseType,
        onRepCounted: @escaping () -> Void,
        onFramingChanged: @escaping (FramingStatus) -> Void,
        onFeedbackChanged: @escaping (String) -> Void = { _ in }
    ) {
        self.metric = exercise.metric
        self.onRepCounted = onRepCounted
        self.onFramingChanged = onFramingChanged
        self.onFeedbackChanged = onFeedbackChanged
        let t = Self.thresholds(for: exercise)
        self.bottomThreshold = t.bottom
        self.standThreshold = t.stand
    }

    /// Reasonable starting thresholds per exercise, based on typical
    /// biomechanics rather than one-size-fits-all numbers. These are
    /// STARTING POINTS — validate against real footage once you have device
    /// access and adjust to taste (e.g. if it's under-counting shallow reps
    /// from less mobile users, raise `bottom`; if it's over-triggering on
    /// small movements, lower `stand` less aggressively).
    private static func thresholds(for exercise: ExerciseType) -> (bottom: CGFloat, stand: CGFloat) {
        switch exercise {
        case .squats:
            // A "parallel" squat (thighs roughly level) puts the knee around
            // 90-100°; deep squats go lower. 100° is a reasonable "counts as
            // a real squat" line without demanding gym-level depth.
            return (bottom: 100, stand: 165)
        case .seatedSquat:
            // Sit-to-stand naturally has a shallower range than a standing
            // squat (you start already bent, at chair height) — and this is
            // the "getting started" exercise, so we deliberately don't
            // demand full leg extension at the top, which some users (older,
            // less mobile, the exact audience for this exercise) may not
            // comfortably reach.
            return (bottom: 110, stand: 155)
        case .wallPushup:
            // Wall push-ups have a much shallower elbow bend than a floor
            // push-up — the body barely leans in. Demanding a floor-pushup
            // depth here would make this exercise nearly impossible to
            // "complete," defeating its purpose as the gentlest starting
            // option.
            return (bottom: 115, stand: 160)
        case .kneePushup:
            // A middle ground: more bend than wall, less than full floor.
            return (bottom: 100, stand: 155)
        case .floorPushup:
            // Full range of motion expected — chest genuinely approaches
            // the floor, arms genuinely straighten at the top.
            return (bottom: 90, stand: 160)
        case .mix, .both:
            // Never queried directly — PoseCounter is always constructed
            // for the CURRENT concrete exercise (see HeyUpViewModel.currentExercise).
            return (bottom: 100, stand: 160)
        }
    }

    /// Call once per camera frame (CameraManager does this on its capture queue).
    /// `orientation` must reflect how the buffer is actually rotated relative
    /// to upright — for the front camera in portrait that's `.leftMirrored`.
    /// Passing the wrong orientation is the single biggest cause of bad
    /// detection: Vision will be reading a sideways/mirrored image and the
    /// joint angles it reports won't mean what this class assumes they mean.
    func process(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let request = VNDetectHumanBodyPoseRequest()
        do {
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)
        } catch {
            return
        }
        guard let observation = request.results?.first else {
            DispatchQueue.main.async { self.onFramingChanged(.searching) }
            return
        }
        guard let points = try? observation.recognizedPoints(.all) else { return }
        evaluate(points: points)
    }

    private func evaluate(points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        switch metric {
        case .kneeAngle:
            // Hip → knee → ankle: the knee is the vertex, per Vision's landmark set.
            evaluateBestSide(
                right: (.rightHip, .rightKnee, .rightAnkle),
                left: (.leftHip, .leftKnee, .leftAnkle),
                points: points, jointLabel: "knees and ankles"
            )
        case .elbowAngle:
            // Shoulder → elbow → wrist: the elbow is the vertex.
            evaluateBestSide(
                right: (.rightShoulder, .rightElbow, .rightWrist),
                left: (.leftShoulder, .leftElbow, .leftWrist),
                points: points, jointLabel: "arms"
            )
        }
    }

    /// Picks whichever side (left or right) has all three landmarks
    /// confidently visible this frame — falling back to the other side
    /// automatically — then drives the phase state machine off that angle.
    private func evaluateBestSide(
        right: (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName),
        left: (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName),
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        jointLabel: String
    ) {
        let rightConfidence = minConfidence(points, right.0, right.1, right.2)
        let leftConfidence = minConfidence(points, left.0, left.1, left.2)
        let useRight = rightConfidence >= leftConfidence
        let chosen = useRight ? right : left
        let bestConfidence = useRight ? rightConfidence : leftConfidence

        guard bestConfidence > confidenceThreshold,
              let pa = points[chosen.0], let pb = points[chosen.1], let pc = points[chosen.2] else {
            DispatchQueue.main.async { self.onFramingChanged(.tooClose(missingJoint: jointLabel)) }
            // A dropped frame shouldn't count toward confirming a phase
            // change — reset the pending-phase counter so we don't confirm
            // off stale/guessed data.
            pendingPhase = nil
            pendingPhaseFrames = 0
            return
        }
        DispatchQueue.main.async { self.onFramingChanged(.good) }

        let angle = Self.angleDegrees(at: pb.location, from: pa.location, to: pc.location)
        advancePhase(angle: angle)
    }

    private func minConfidence(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        _ a: VNHumanBodyPoseObservation.JointName,
        _ b: VNHumanBodyPoseObservation.JointName,
        _ c: VNHumanBodyPoseObservation.JointName
    ) -> VNConfidence {
        guard let pa = points[a], let pb = points[b], let pc = points[c] else { return 0 }
        return min(pa.confidence, min(pb.confidence, pc.confidence))
    }

    // MARK: - Phase state machine
    //
    // Only two thresholds drive five phases, based on where the angle sits
    // AND what phase we were already in — that's what makes "lowering" vs
    // "rising" meaningful without needing to track velocity:
    //
    //   angle >= standThreshold   → fully extended zone
    //   angle <= bottomThreshold  → fully bent zone
    //   in between                → transitional zone, direction inferred
    //                                from the phase we're coming from
    //
    // standing --(drops below stand)--> lowering --(reaches bottom)--> bottom
    //   --(rises above bottom)--> rising --(reaches stand)--> completed → standing
    //
    // A rep is only ever counted on the rising→completed edge, which
    // requires having genuinely passed through `bottom` first — so a small
    // wobble near the top can't be mistaken for a rep, and a single rep
    // can't double-count without a fresh trip through the bottom again.

    private func advancePhase(angle: CGFloat) {
        let candidate = nextPhase(for: angle)
        guard candidate != phase else {
            pendingPhase = nil
            pendingPhaseFrames = 0
            reportFeedback()
            return
        }

        if pendingPhase == candidate {
            pendingPhaseFrames += 1
        } else {
            pendingPhase = candidate
            pendingPhaseFrames = 1
        }

        guard pendingPhaseFrames >= framesToConfirm else { return }

        phase = candidate
        pendingPhase = nil
        pendingPhaseFrames = 0

        if phase == .completed {
            let now = Date()
            if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                lastRepTime = now
                DispatchQueue.main.async { self.onRepCounted() }
            }
            // Report "Rep counted" WHILE still in .completed — relaxing to
            // .standing first (as this used to do) meant reportFeedback()
            // below would read the already-reset phase and show "Stand
            // tall"/"Arms extended" instead, so the "Rep counted" message
            // could never actually appear. Report, THEN relax, THEN return
            // (skip the trailing reportFeedback() call at the bottom so it
            // doesn't immediately overwrite this with the standing message).
            reportFeedback()
            phase = .standing
            return
        }

        reportFeedback()
    }

    /// What phase the CURRENT angle implies, given the phase we're already in.
    private func nextPhase(for angle: CGFloat) -> RepPhase {
        switch phase {
        case .standing:
            return angle >= standThreshold ? .standing : .lowering
        case .lowering:
            if angle <= bottomThreshold { return .bottom }
            if angle >= standThreshold { return .standing } // aborted before reaching depth
            return .lowering
        case .bottom:
            return angle > bottomThreshold ? .rising : .bottom
        case .rising:
            if angle >= standThreshold { return .completed }
            if angle <= bottomThreshold { return .bottom } // sank back down, e.g. a pulse rep
            return .rising
        case .completed:
            return .standing // transient; never actually queried in this phase
        }
    }

    private func reportFeedback() {
        let text: String
        switch metric {
        case .kneeAngle:
            switch phase {
            case .standing: text = "Stand tall"
            case .lowering: text = "Lower down"
            case .bottom: text = "Good squat"
            case .rising: text = "Rise up"
            case .completed: text = "Rep counted"
            }
        case .elbowAngle:
            switch phase {
            case .standing: text = "Arms extended"
            case .lowering: text = "Lower down"
            case .bottom: text = "Good depth"
            case .rising: text = "Push up"
            case .completed: text = "Rep counted"
            }
        }
        // Dispatched to main — this fires from the camera's background
        // sample-buffer queue (see CameraManager), and repFeedback is an
        // @Published property the UI binds to directly.
        DispatchQueue.main.async { self.onFeedbackChanged(text) }
    }

    /// Angle ABC in degrees, where B is the vertex (e.g. the knee or elbow).
    private static func angleDegrees(at vertex: CGPoint, from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: p1.x - vertex.x, dy: p1.y - vertex.y)
        let v2 = CGVector(dx: p2.x - vertex.x, dy: p2.y - vertex.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let mag2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        guard mag1 > 0, mag2 > 0 else { return 180 }
        let cosAngle = max(-1, min(1, dot / (mag1 * mag2)))
        return acos(cosAngle) * 180 / .pi
    }
}
