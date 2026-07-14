import Foundation

/// Every exercise HeyUp can count, plus the two meta-modes ("mix" rotates
/// through them one break at a time; "both" runs two in the same break).
enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case squats
    case seatedSquat
    case wallPushup
    case kneePushup
    case floorPushup
    case mix
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squats: return "Squats"
        case .seatedSquat: return "Seated Squat"
        case .wallPushup: return "Wall push-ups"
        case .kneePushup: return "Knee push-ups"
        case .floorPushup: return "Floor push-ups"
        case .mix: return "Mix it up"
        case .both: return "Both — push-ups + squats"
        }
    }

    /// Real, camera-countable exercises only (excludes the meta-modes).
    static var countable: [ExerciseType] {
        [.squats, .seatedSquat, .wallPushup, .kneePushup, .floorPushup]
    }

    /// Which Vision joint-angle metric this exercise is counted with.
    /// Squats and the seated squat both use the knee angle (hip-knee-ankle);
    /// all push-up variants use the elbow angle (shoulder-elbow-wrist).
    /// See PoseCounter.swift for why one metric works for several exercises.
    var metric: RepMetric {
        switch self {
        case .squats, .seatedSquat: return .kneeAngle
        case .wallPushup, .kneePushup, .floorPushup: return .elbowAngle
        case .mix, .both: return .kneeAngle // never queried directly; resolved per-phase
        }
    }

    var setupCues: [String] {
        switch self {
        case .squats:
            return ["Prop your phone up so it faces you",
                    "Step back until your whole body is in frame",
                    "Squat until thighs are parallel, then stand tall"]
        case .seatedSquat:
            return ["Prop your phone to your side",
                    "Sit tall near the front of your seat",
                    "Stand fully up, then sit back down — no hands"]
        case .wallPushup:
            return ["Prop your phone to your side",
                    "Hands on the wall at shoulder height, feet back",
                    "Bend elbows to bring chest to the wall, push back"]
        case .kneePushup:
            return ["Prop your phone low, to your side",
                    "Knees down, hands under your shoulders",
                    "Lower your chest, then press back up"]
        case .floorPushup:
            return ["Prop your phone low, to your side",
                    "Place it far enough back to fit your whole body",
                    "Lower chest to the floor, elbows at 45°"]
        case .mix:
            return ["Prop your phone up so it can see you"]
        case .both:
            return ["Prop your phone up so it can see you for both parts",
                    "We'll tell you when to switch"]
        }
    }
}

/// Which joint-angle a rep counter should track for a given exercise.
enum RepMetric {
    case kneeAngle
    case elbowAngle
}
