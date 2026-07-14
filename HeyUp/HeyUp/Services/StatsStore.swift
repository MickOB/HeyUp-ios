import Foundation
import Combine

/// Persists today's + past days' stats and the streak, all via UserDefaults —
/// no accounts, no cloud, per MVP scope. Each day gets its own key so a
/// "this week" view can look back without loading everything at once.
final class StatsStore: ObservableObject {
    static let shared = StatsStore()

    @Published private(set) var today: DailyStats
    @Published private(set) var streak: Int

    private let calendar = Calendar.current
    private let defaults = UserDefaults.standard

    private init() {
        self.today = Self.load(for: Date()) ?? DailyStats()
        self.streak = defaults.integer(forKey: Self.streakKey)
    }

    // MARK: - Keys

    private static func key(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "heyup-stats-\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
    private static let streakKey = "heyup-streak"
    private static let lastCompletedDateKey = "heyup-last-completed-date"

    private static func load(for date: Date) -> DailyStats? {
        guard let data = UserDefaults.standard.data(forKey: key(for: date)) else { return nil }
        return try? JSONDecoder().decode(DailyStats.self, from: data)
    }

    private func save(_ stats: DailyStats, for date: Date) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: Self.key(for: date))
    }

    /// Re-syncs `today` to whatever calendar day it actually is right now.
    /// Without this, an app left open across midnight would keep mutating
    /// the in-memory `today` object (still yesterday's data) and then save
    /// it under TODAY's new date key — silently corrupting the new day's
    /// stats with yesterday's totals. Call at the top of every mutation.
    private func rolloverIfNewDay() {
        guard !calendar.isDateInToday(lastKnownDay) else { return }
        lastKnownDay = Date()
        today = Self.load(for: Date()) ?? DailyStats()
    }
    private var lastKnownDay: Date = Date()

    // MARK: - Mutations

    /// Call when a break finishes successfully. `exercises` lists each
    /// exercise completed in this break with its rep count — for "both" mode
    /// this has two entries; otherwise just one.
    func logCompletedBreak(reps: Int, exercises: [(ExerciseType, Int)]) {
        rolloverIfNewDay()
        today.logCompletedBreak(reps: reps, exercises: exercises)
        save(today, for: Date())
        bumpStreak()
    }

    func logSkip() {
        rolloverIfNewDay()
        today.logSkip()
        save(today, for: Date())
    }

    func resetToday() {
        rolloverIfNewDay()
        today = DailyStats()
        save(today, for: Date())
    }

    /// Also used by the week view so a day rendered right after midnight
    /// (with the app already open) reflects the fresh empty day, not stale
    /// in-memory data.
    func refreshIfNewDay() { rolloverIfNewDay() }

    /// A streak day counts once you've completed at least one break; it only
    /// increments the first time each calendar day, and resets if you miss
    /// a full day (checked against the last date you completed a break).
    private func bumpStreak() {
        let now = Date()
        if let lastData = defaults.object(forKey: Self.lastCompletedDateKey) as? Date {
            if calendar.isDateInToday(lastData) {
                return // already counted today
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            if calendar.isDate(lastData, inSameDayAs: yesterday) {
                streak += 1
            } else {
                streak = 1 // missed a day — restart
            }
        } else {
            streak = 1
        }
        defaults.set(now, forKey: Self.lastCompletedDateKey)
        defaults.set(streak, forKey: Self.streakKey)
    }

    /// Current calendar week, Monday through Sunday, so the strip always
    /// starts on Monday regardless of what day it is today (a rolling
    /// "last 7 days" window was landing on odd starting weekdays).
    func weekHistory() -> [(date: Date, stats: DailyStats)] {
        rolloverIfNewDay()
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2 // Monday
        let weekStart = mondayFirst.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let stats = calendar.isDateInToday(date) ? today : (Self.load(for: date) ?? DailyStats())
            return (date, stats)
        }
    }

    /// Reads one calendar day's stats without mutating anything — used by
    /// the History screen to build week/month/year rollups. Returns an
    /// empty DailyStats for days that were never logged (so month/year
    /// tabulation just naturally fills in the longer someone uses HeyUp).
    func stats(for date: Date) -> DailyStats {
        calendar.isDateInToday(date) ? today : (Self.load(for: date) ?? DailyStats())
    }
}
