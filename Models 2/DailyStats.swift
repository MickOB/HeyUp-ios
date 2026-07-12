import Foundation

/// One day's worth of break activity. Encoded to JSON and stored under a
/// per-date UserDefaults key by StatsStore (e.g. "heyup-stats-2026-7-9").
struct DailyStats: Codable {
    var completed: Int = 0
    var skipped: Int = 0
    var totalReps: Int = 0
    /// Reps logged per exercise, so a future "This week" chart can show the
    /// mix (e.g. squats vs. wall push-ups) the same way the prototype does.
    var repsByExercise: [String: Int] = [:]

    mutating func logCompletedBreak(reps: Int, exercises: [(ExerciseType, Int)]) {
        completed += 1
        totalReps += reps
        for (exercise, count) in exercises {
            repsByExercise[exercise.rawValue, default: 0] += count
        }
    }

    mutating func logSkip() {
        skipped += 1
    }
}
