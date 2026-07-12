import Foundation

/// What the user is doing between breaks — drives copy only (TV vs. work vs.
/// general downtime), not the counting logic.
enum SessionType: String, Codable, CaseIterable, Identifiable {
    case tv
    case office
    case dailyLife

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tv: return "TV time"
        case .office: return "Home office"
        case .dailyLife: return "Daily life"
        }
    }

    var timerHeading: String {
        switch self {
        case .tv: return "TV TIME"
        case .office: return "FOCUS TIME"
        case .dailyLife: return "ON THE CLOCK"
        }
    }

    var waitingCopy: String {
        switch self {
        case .tv: return "Enjoy your show. I'll tap you on the shoulder when it's time to move."
        case .office: return "Heads down. I'll pull you up for a stretch when the block is done."
        case .dailyLife: return "Go about your day. I'll tap you on the shoulder when it's time to move."
        }
    }

    func oneMinuteWarning() -> String {
        switch self {
        case .tv: return "One minute left. Pause the show when you're ready."
        case .office: return "One minute left. Finish that thought."
        case .dailyLife: return "One minute left. Wrap up what you're doing."
        }
    }

    func successHeadline() -> String {
        switch self {
        case .tv: return "You earned your next TV block"
        case .office: return "You earned your next focus block"
        case .dailyLife: return "You earned your next break"
        }
    }
}
