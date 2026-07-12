import Foundation

enum FitnessLevel: String, Codable, CaseIterable {
    case gettingStarted = "Just getting started"
    case moveABit = "I move a bit"
    case prettyActive = "Pretty active"
    case veryActive = "Very active"
}

enum AgeRange: String, Codable, CaseIterable {
    case under30 = "Under 30"
    case thirtyTo40 = "30–40"
    case fortyOneTo50 = "41–50"
    case fiftyOneTo60 = "51–60"
    case sixtyPlus = "60+"
    case preferNotToSay = "Prefer not to say"

    var is51OrOlder: Bool { self == .fiftyOneTo60 || self == .sixtyPlus }
}

/// Answers collected during onboarding. Persisted to UserDefaults as JSON —
/// no accounts, no cloud sync per MVP scope.
struct UserProfile: Codable {
    var name: String = ""
    var sex: String = ""
    var ageRange: AgeRange?
    var fitness: FitnessLevel?
    var source: String = ""

    /// The plan the app recommends at the end of onboarding: which exercises
    /// to start with and how many reps. Mirrors the HTML prototype's rules.
    struct StartingPlan {
        let push: ExerciseType
        let legs: ExerciseType
        let reps: Int
    }

    func recommendedPlan() -> StartingPlan {
        let older = ageRange?.is51OrOlder ?? false
        switch fitness {
        case .veryActive:
            return StartingPlan(push: .floorPushup, legs: .squats, reps: older ? 8 : 10)
        case .prettyActive:
            return older
                ? StartingPlan(push: .kneePushup, legs: .squats, reps: 5)
                : StartingPlan(push: .floorPushup, legs: .squats, reps: 8)
        case .moveABit:
            return StartingPlan(push: .kneePushup, legs: .squats, reps: 5)
        case .gettingStarted, .none:
            return StartingPlan(push: .wallPushup, legs: .seatedSquat, reps: 5)
        }
    }
}
