import Foundation
import Combine
import AVFoundation

enum AppScreen {
    case onboarding
    case home
    case history
    case timer
    case getReady
    case movementBreak
    case skipCheckIn
    case success
    case settings
}

/// Central state machine for the whole app — mirrors the HTML prototype's
/// single ViewModel. Views read published state and call these methods;
/// nothing here touches UI directly.
final class HeyUpViewModel: ObservableObject {
    // MARK: - Persisted user choices
    //
    // Every one of these persists itself to UserDefaults via didSet, and
    // `loadPersistedSettings()` (called from init) reads them back — without
    // this, the app would silently reset to onboarding + defaults on every
    // normal relaunch, which is exactly what the pre-fix version did.
    @Published var profile = UserProfile() {
        didSet { persistProfile() }
    }
    @Published var intervalMinutes: Int = 30 {
        didSet { UserDefaults.standard.set(intervalMinutes, forKey: Self.intervalKey) }
    }
    @Published var sessionLengthHours: Int = 4 {
        didSet { UserDefaults.standard.set(sessionLengthHours, forKey: Self.sessionHoursKey) }
    }
    @Published var sessionType: SessionType = .tv {
        didSet { UserDefaults.standard.set(sessionType.rawValue, forKey: Self.sessionTypeKey) }
    }
    @Published var exercise: ExerciseType = .wallPushup {
        didSet { UserDefaults.standard.set(exercise.rawValue, forKey: Self.exerciseKey) }
    }
    @Published var comboUpper: ExerciseType = .wallPushup {   // used when exercise == .both
        didSet { UserDefaults.standard.set(comboUpper.rawValue, forKey: Self.comboUpperKey) }
    }
    @Published var comboLower: ExerciseType = .squats {       // used when exercise == .both
        didSet { UserDefaults.standard.set(comboLower.rawValue, forKey: Self.comboLowerKey) }
    }
    @Published var repGoal: Int = 5 {
        didSet { UserDefaults.standard.set(repGoal, forKey: Self.repGoalKey) }
    }

    // MARK: - Navigation / session state
    @Published var screen: AppScreen = .onboarding
    @Published var secondsLeft: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isPaused = false
    @Published var showOneMinuteWarning = false

    // MARK: - Break state
    @Published var reps: Int = 0
    @Published var breakPhase: Int = 1 // 1 or 2, only meaningful when exercise == .both
    @Published var isResting = false
    @Published var restSecondsLeft: Int = 0
    @Published var framingStatus: FramingStatus = .searching
    @Published var repFeedback: String = ""
    @Published var skipStreak: Int = 0

    /// When the CURRENT watch/work session started (set once, when the user
    /// taps Start on Home) — used to stop auto-reminding after
    /// `sessionLengthHours`, so a movie night doesn't turn into 2am nudges.
    @Published var sessionStartTime: Date? {
        didSet {
            if let sessionStartTime {
                UserDefaults.standard.set(sessionStartTime.timeIntervalSince1970, forKey: Self.sessionStartKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.sessionStartKey)
            }
        }
    }
    /// True right after the session-length cutoff ends a session, so Home
    /// can show a quick "that's a wrap" message instead of just looking idle.
    @Published var sessionEnded = false
    /// True after the user denied camera access — drives the "enable in
    /// Settings" fallback screen instead of a silent blank camera view.
    @Published var cameraAccessDenied = false

    /// Wall-clock deadline for the current countdown. Using an absolute
    /// Date (not a tick counter) means the timer stays accurate even if iOS
    /// suspends our per-second Timer while the app is backgrounded — we
    /// just recompute `secondsLeft` from `Date()` whenever we get a chance
    /// to run again (including right when the app returns to foreground;
    /// see RootView's scenePhase handling).
    private var sessionEndDate: Date? {
        didSet {
            // Persisted so a countdown survives the app being fully killed by
            // iOS while backgrounded (not just suspended) — without this, a
            // user who gets their phone locked for hours mid-session would
            // reopen HeyUp to a countdown that silently reset to the full
            // interval instead of picking up where it left off.
            if let sessionEndDate {
                UserDefaults.standard.set(sessionEndDate.timeIntervalSince1970, forKey: Self.persistedEndDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.persistedEndDateKey)
            }
        }
    }
    private static let persistedEndDateKey = "heyup-session-end-date"
    private static let intervalKey = "heyup-interval-minutes"
    private static let sessionHoursKey = "heyup-session-hours"
    private static let sessionTypeKey = "heyup-session-type"
    private static let exerciseKey = "heyup-exercise"
    private static let comboUpperKey = "heyup-combo-upper"
    private static let comboLowerKey = "heyup-combo-lower"
    private static let repGoalKey = "heyup-rep-goal"
    private static let sessionStartKey = "heyup-session-start"
    private static let pausedKey = "heyup-paused"
    private static let pausedRemainingKey = "heyup-paused-remaining"
    private static let profileKey = "heyup-profile"

    let statsStore = StatsStore.shared
    let cameraManager = CameraManager()
    private var poseCounter: PoseCounter?
    private var timerCancellable: AnyCancellable?
    private var restCancellable: AnyCancellable?
    private var mixIndex = 0

    private let mixRotation: [ExerciseType] = [.squats, .seatedSquat, .wallPushup, .kneePushup, .floorPushup]

    init() {
        loadPersistedSettings()
        restorePersistedSession()
    }

    /// Reads back everything persisted below, including whether onboarding
    /// was already completed (a saved profile means yes) — so a normal
    /// relaunch lands on Home, not back at onboarding.
    private func loadPersistedSettings() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: Self.profileKey), let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = saved
            screen = .home // onboarding already completed in a past session
        }
        if d.object(forKey: Self.intervalKey) != nil { intervalMinutes = d.integer(forKey: Self.intervalKey) }
        if d.object(forKey: Self.sessionHoursKey) != nil { sessionLengthHours = d.integer(forKey: Self.sessionHoursKey) }
        if let raw = d.string(forKey: Self.sessionTypeKey), let t = SessionType(rawValue: raw) { sessionType = t }
        if let raw = d.string(forKey: Self.exerciseKey), let e = ExerciseType(rawValue: raw) { exercise = e }
        if let raw = d.string(forKey: Self.comboUpperKey), let e = ExerciseType(rawValue: raw) { comboUpper = e }
        if let raw = d.string(forKey: Self.comboLowerKey), let e = ExerciseType(rawValue: raw) { comboLower = e }
        if d.object(forKey: Self.repGoalKey) != nil { repGoal = d.integer(forKey: Self.repGoalKey) }
        if let stored = d.object(forKey: Self.sessionStartKey) as? Double, stored > 0 {
            sessionStartTime = Date(timeIntervalSince1970: stored)
        }
    }

    /// Called once at launch. If the app was killed mid-countdown (not just
    /// backgrounded), this picks the timer back up from where it really is —
    /// or, if the countdown already finished while we were gone, jumps
    /// straight to Get Ready rather than pretending no time passed.
    private func restorePersistedSession() {
        // Was mid-countdown but PAUSED when the app was killed — restore the
        // paused state as-is rather than falling through to the deadline
        // check below, which would otherwise treat the still-in-the-future
        // original deadline as a live countdown and silently resume it,
        // ignoring that the user deliberately paused.
        if UserDefaults.standard.bool(forKey: Self.pausedKey) {
            let remaining = UserDefaults.standard.integer(forKey: Self.pausedRemainingKey)
            guard remaining > 0 else { return }
            secondsLeft = remaining
            totalSeconds = intervalMinutes * 60
            isPaused = true
            screen = .timer
            return
        }
        let stored = UserDefaults.standard.double(forKey: Self.persistedEndDateKey)
        guard stored > 0 else { return }
        let endDate = Date(timeIntervalSince1970: stored)
        guard endDate.timeIntervalSinceNow > -3600 else {
            // Over an hour past due — likely a stale value from days ago
            // (e.g. the app was killed and never reopened same-session).
            // Don't spring a break screen on the user out of nowhere; just
            // clear it and let them start fresh from Home.
            UserDefaults.standard.removeObject(forKey: Self.persistedEndDateKey)
            return
        }
        sessionEndDate = endDate
        totalSeconds = intervalMinutes * 60
        if endDate.timeIntervalSinceNow <= 0 {
            screen = .getReady
        } else {
            secondsLeft = Int(ceil(endDate.timeIntervalSinceNow))
            screen = .timer
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
                self?.tick()
            }
        }
    }

    // MARK: - Derived helpers

    /// The exercise actually being counted RIGHT NOW — resolves "mix" and
    /// "both" down to a concrete, countable exercise.
    var currentExercise: ExerciseType {
        switch exercise {
        case .both: return breakPhase == 1 ? comboUpper : comboLower
        case .mix: return mixRotation[mixIndex % mixRotation.count]
        default: return exercise
        }
    }

    // MARK: - Onboarding

    func finishOnboarding() {
        let plan = profile.recommendedPlan()
        exercise = plan.push == .floorPushup ? .floorPushup : plan.push
        comboUpper = plan.push
        comboLower = plan.legs
        repGoal = plan.reps
        screen = .home
        persistProfile()
    }

    private func persistProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.profileKey)
        }
    }

    // MARK: - Timer

    /// Call this from the Home screen's Start button — begins a brand new
    /// watch/work session and starts its "stop reminding after N hours" clock.
    func startSessionFromHome() {
        sessionStartTime = Date()
        sessionEnded = false
        startTimer()
    }

    func startTimer() {
        NotificationManager.shared.cancelAll()
        let seconds = intervalMinutes * 60
        totalSeconds = seconds
        secondsLeft = seconds
        sessionEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        isPaused = false
        UserDefaults.standard.set(false, forKey: Self.pausedKey)
        UserDefaults.standard.removeObject(forKey: Self.pausedRemainingKey)
        screen = .timer
        NotificationManager.shared.scheduleSessionNotifications(totalSeconds: TimeInterval(seconds), session: sessionType)

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }

    /// Recomputes secondsLeft from the wall-clock deadline rather than just
    /// decrementing by one. Safe to call as often as you like — e.g. from
    /// the per-second Timer, or once right when the app returns to the
    /// foreground after being backgrounded for a while.
    private func tick() {
        guard screen == .timer, !isPaused, let endDate = sessionEndDate else { return }
        let remaining = Int(ceil(endDate.timeIntervalSinceNow))
        if remaining <= 0 {
            secondsLeft = 0
            timerCancellable?.cancel()
            sessionEndDate = nil // countdown is done — nothing left to restore on relaunch
            showOneMinuteWarning = false
            startGetReady()
        } else {
            secondsLeft = remaining
            // Show an in-app banner mirroring the 1-minute-warning notification,
            // for whenever HeyUp is already in the foreground to see it.
            if remaining == 60 && totalSeconds > 60 {
                showOneMinuteWarning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
                    self?.showOneMinuteWarning = false
                }
            }
        }
    }

    /// Call when the app returns to the foreground (see RootView's
    /// `.onChange(of: scenePhase)`) so a countdown that finished while
    /// backgrounded is caught immediately rather than sitting stale.
    func refreshTimerIfNeeded() {
        tick()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            // Freeze exactly where we are, and don't let a stale notification
            // fire mid-pause (e.g. the 1-minute warning while the user has
            // deliberately stopped the clock). Drop the live wall-clock
            // deadline and persist the frozen remaining time + paused flag
            // instead — otherwise a force-quit while paused would restore
            // from the ORIGINAL (still-in-the-future) deadline on relaunch
            // and silently resume counting down, ignoring the pause.
            sessionEndDate = nil
            UserDefaults.standard.set(true, forKey: Self.pausedKey)
            UserDefaults.standard.set(secondsLeft, forKey: Self.pausedRemainingKey)
            NotificationManager.shared.cancelAll()
        } else {
            // Resuming: re-anchor the wall-clock deadline to "now + however
            // much was left", then reschedule notifications against that.
            UserDefaults.standard.set(false, forKey: Self.pausedKey)
            UserDefaults.standard.removeObject(forKey: Self.pausedRemainingKey)
            sessionEndDate = Date().addingTimeInterval(TimeInterval(secondsLeft))
            NotificationManager.shared.scheduleSessionNotifications(totalSeconds: TimeInterval(secondsLeft), session: sessionType)
        }
    }

    func skipToBreakNow() {
        timerCancellable?.cancel()
        NotificationManager.shared.cancelAll()
        startGetReady()
    }

    // MARK: - Get ready → movement break

    private func startGetReady() {
        screen = .getReady
    }

    func beginMovementBreak() {
        reps = 0
        breakPhase = 1
        isResting = false
        framingStatus = .searching
        cameraAccessDenied = false
        screen = .movementBreak
        cameraManager.requestAccess { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.cameraAccessDenied = true
                return
            }
            self.attachPoseCounter()
            self.cameraManager.startSession(counter: self.poseCounter!)
        }
    }

    private func attachPoseCounter() {
        poseCounter = PoseCounter(
            exercise: currentExercise,
            onRepCounted: { [weak self] in self?.handleRepCounted() },
            onFramingChanged: { [weak self] status in self?.framingStatus = status },
            onFeedbackChanged: { [weak self] text in self?.repFeedback = text }
        )
    }

    private func handleRepCounted() {
        guard reps < repGoal else { return }
        reps += 1
        guard reps >= repGoal else { return }

        if exercise == .both && breakPhase == 1 {
            startRestBetweenPhases()
        } else {
            finishBreak()
        }
    }

    private func startRestBetweenPhases() {
        cameraManager.stopSession()
        isResting = true
        restSecondsLeft = 10
        restCancellable = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            if self.restSecondsLeft <= 1 {
                self.restCancellable?.cancel()
                self.isResting = false
                self.breakPhase = 2
                self.reps = 0
                self.attachPoseCounter()
                self.cameraManager.startSession(counter: self.poseCounter!)
            } else {
                self.restSecondsLeft -= 1
            }
        }
    }

    private func finishBreak() {
        cameraManager.stopSession()
        var exercises: [(ExerciseType, Int)] = []
        if exercise == .both {
            exercises = [(comboUpper, repGoal), (comboLower, repGoal)]
        } else {
            exercises = [(currentExercise, repGoal)]
        }
        let totalReps = exercises.reduce(0) { $0 + $1.1 }
        statsStore.logCompletedBreak(reps: totalReps, exercises: exercises)
        skipStreak = 0
        if exercise == .mix { mixIndex += 1 }
        screen = .success
        scheduleAutoRestart()
    }

    private func scheduleAutoRestart() {
        // Auto-restarts the next block after a few seconds on the success screen —
        // unless the "stop reminding after" window for this session has elapsed.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.screen == .success else { return }
            if let start = self.sessionStartTime,
               Date().timeIntervalSince(start) >= TimeInterval(self.sessionLengthHours) * 3600 {
                self.sessionStartTime = nil
                self.sessionEnded = true
                self.screen = .home
            } else {
                self.startTimer()
            }
        }
    }

    // MARK: - Skip

    func skipBreak() {
        statsStore.logSkip()
        skipStreak += 1
        cameraManager.stopSession()
        if skipStreak >= 2 {
            screen = .skipCheckIn
        } else {
            startTimer()
        }
    }

    func easeUpAfterSkips() {
        let stepDown: [ExerciseType: ExerciseType] = [
            .floorPushup: .kneePushup, .kneePushup: .wallPushup, .wallPushup: .wallPushup,
            .squats: .seatedSquat, .seatedSquat: .seatedSquat
        ]
        if exercise == .both {
            comboUpper = stepDown[comboUpper] ?? comboUpper
        } else if let easier = stepDown[exercise] {
            exercise = easier
        }
        repGoal = 5
        skipStreak = 0
        startTimer()
    }

    func keepGoingAfterSkips() {
        skipStreak = 0
        startTimer()
    }

    // MARK: - Navigation

    func goHome() {
        timerCancellable?.cancel()
        restCancellable?.cancel()
        cameraManager.stopSession()
        NotificationManager.shared.cancelAll()
        sessionStartTime = nil
        sessionEnded = false
        sessionEndDate = nil
        UserDefaults.standard.set(false, forKey: Self.pausedKey)
        UserDefaults.standard.removeObject(forKey: Self.pausedRemainingKey)
        screen = .home
    }

    func openSettings() { screen = .settings }
    func closeSettings() { screen = .home }
    func openHistory() { screen = .history }
    func closeHistory() { screen = .home }

    // MARK: - History rollups (week / month / year)

    /// Groups the last 7 days, 5 weeks, or 12 months into bars for the
    /// History screen — same shape regardless of range, so the view can
    /// render all three identically.
    struct HistoryBucket {
        let label: String
        let totalReps: Int
        let repsByExercise: [String: Int]
        let isCurrent: Bool
    }

    func historyBuckets(range: HistoryRange) -> [HistoryBucket] {
        let cal = Calendar.current
        let today = Date()
        switch range {
        case .week:
            return (0..<7).reversed().map { offset in
                let date = cal.date(byAdding: .day, value: -offset, to: today)!
                let stats = statsStore.stats(for: date)
                let f = DateFormatter(); f.dateFormat = "EEE"
                return HistoryBucket(label: f.string(from: date), totalReps: stats.totalReps, repsByExercise: stats.repsByExercise, isCurrent: offset == 0)
            }
        case .month:
            return (0..<5).reversed().map { weekOffset in
                var totalReps = 0
                var byEx: [String: Int] = [:]
                var weekStart: Date = today
                for dayOffset in 0..<7 {
                    let date = cal.date(byAdding: .day, value: -(weekOffset * 7 + dayOffset), to: today)!
                    if dayOffset == 6 { weekStart = date }
                    let stats = statsStore.stats(for: date)
                    totalReps += stats.totalReps
                    for (k, v) in stats.repsByExercise { byEx[k, default: 0] += v }
                }
                let f = DateFormatter(); f.dateFormat = "MMM d"
                return HistoryBucket(label: f.string(from: weekStart), totalReps: totalReps, repsByExercise: byEx, isCurrent: weekOffset == 0)
            }
        case .year:
            return (0..<12).reversed().map { monthOffset in
                let monthDate = cal.date(byAdding: .month, value: -monthOffset, to: today)!
                let range = cal.range(of: .day, in: .month, for: monthDate) ?? (1..<1)
                var totalReps = 0
                var byEx: [String: Int] = [:]
                for day in range {
                    var comps = cal.dateComponents([.year, .month], from: monthDate)
                    comps.day = day
                    guard let date = cal.date(from: comps), date <= today else { continue }
                    let stats = statsStore.stats(for: date)
                    totalReps += stats.totalReps
                    for (k, v) in stats.repsByExercise { byEx[k, default: 0] += v }
                }
                let f = DateFormatter(); f.dateFormat = "MMM"
                return HistoryBucket(label: f.string(from: monthDate), totalReps: totalReps, repsByExercise: byEx, isCurrent: monthOffset == 0)
            }
        }
    }
}

enum HistoryRange: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }
    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}
