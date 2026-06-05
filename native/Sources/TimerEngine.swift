import SwiftUI
import Combine

struct LogEntry: Identifiable, Codable {
    var id = UUID()
    let time: String
    let message: String
}

/// Core pomodoro state machine. Phase 1+2: countdown, modes, series/chain,
/// points, levels, activity grid data, today log, reminders, auto-chain,
/// and sound/voice cues — all local. CloudKit sync arrives in Phase 3.
@MainActor
final class TimerEngine: ObservableObject {
    @Published var mode: TimerMode = .work
    @Published var timeLeft: Int = TimerMode.work.duration
    @Published var isRunning = false

    @Published var totalPoints = 0
    @Published var todayCount = 0

    @Published var seriesTarget = 1
    @Published var seriesProgress = 0
    @Published var sessionsCompleted = 0

    @Published var activityData: [String: Int] = [:]   // "yyyy-MM-dd" -> count
    @Published var todayLog: [LogEntry] = []
    @Published var toast: String? = nil

    let settings: AppSettings
    let sound: SoundEngine

    private var ticker: AnyCancellable?
    private var reminderTicker: AnyCancellable?
    private var idleSeconds = 0
    private let defaults = UserDefaults.standard

    init(settings: AppSettings, sound: SoundEngine) {
        self.settings = settings
        self.sound = sound
        sound.masterVolume = settings.systemVolume
        load()
        settings.reminderChanged = { [weak self] in self?.updateReminder() }
        updateReminder()
    }

    // MARK: Derived

    var duration: Int { mode.duration }
    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(duration - timeLeft) / Double(duration) * 100
    }
    var level: Level { Level.forPoints(totalPoints) }
    var isWarning: Bool { timeLeft <= 60 && isRunning }
    var elapsedMinutes: Int { (duration - timeLeft) / 60 }
    var yearTotal: Int { activityData.values.reduce(0, +) }
    var timeString: String { String(format: "%02d:%02d", timeLeft / 60, timeLeft % 60) }

    // MARK: Controls

    func start() {
        guard !isRunning else { return }
        isRunning = true
        sound.masterVolume = settings.systemVolume
        if settings.soundEnabled { sound.tone(220, 0.12); sound.tone(330, 0.12, delay: 0.06) }
        if settings.voiceCuesEnabled { sound.speak(mode == .work ? "Focus" : "Break") }
        log("Started \(mode.label)")
        updateReminder()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        let wasRunning = isRunning
        isRunning = false
        ticker?.cancel(); ticker = nil
        if wasRunning && settings.soundEnabled { sound.tone(330, 0.1); sound.tone(220, 0.1, delay: 0.06) }
        updateReminder()
    }

    func toggle() { isRunning ? pause() : start() }

    func reset() {
        pause()
        timeLeft = duration
    }

    func change(to newMode: TimerMode) {
        pause()
        if settings.soundEnabled { sound.tone(660, 0.08, amp: 0.18) }
        mode = newMode
        timeLeft = newMode.duration
    }

    func setSeries(_ n: Int) {
        seriesTarget = n
        seriesProgress = 0
    }

    // MARK: Tick / completion

    private func tick() {
        guard timeLeft > 0 else { complete(); return }
        timeLeft -= 1

        if settings.tickSoundEnabled { playTick() }

        // Warning beeps at 30 / 20 / 10s
        if settings.soundEnabled, timeLeft <= 30, timeLeft > 0, timeLeft % 10 == 0 {
            sound.tone(330, 0.1, amp: 0.25)
        }

        // Progress beeps: work mode, N beeps at the Nth interval boundary
        if settings.intervalSoundEnabled, mode == .work {
            let interval = settings.beepInterval * 60
            let elapsed = duration - timeLeft
            if elapsed > 0, elapsed % interval == 0 {
                let n = elapsed / interval
                for i in 0..<n { sound.tone(220, 0.12, amp: 0.2, delay: Double(i) * 0.16) }
            }
        }

        if timeLeft == 0 { complete() }
    }

    private func playTick() {
        switch settings.tickStyle {
        case "click":     sound.tone(800, 0.008, .square, amp: 0.15)
        case "pulse":     sound.tone(60, 0.03, .sine, amp: 0.25)
        case "woodblock": sound.tone(1200, 0.012, .triangle, amp: 0.18)
        default:          sound.tone(200, 0.02, .sine, amp: 0.15)   // soft
        }
    }

    private func complete() {
        pause()
        if mode == .work {
            totalPoints += 25
            todayCount += 1
            sessionsCompleted += 1
            activityData[Self.todayKey(), default: 0] += 1
            log("Completed pomodoro! +25 pts")
            if settings.soundEnabled { playCompletionMelody() }
            if settings.voiceCuesEnabled { sound.speak("Pomodoro complete") }
            save()

            if seriesTarget > 1 {
                seriesProgress += 1
                if seriesProgress >= seriesTarget {
                    notify("Series complete! \(seriesTarget) pomodoros done!")
                    seriesProgress = 0
                    change(to: .longBreak)
                } else {
                    let brk: TimerMode = (seriesProgress % 4 == 0) ? .longBreak : .shortBreak
                    notify("\(seriesProgress)/\(seriesTarget) done. Break time!")
                    change(to: brk)
                    autoChain()
                }
            } else {
                notify("Pomodoro complete! +25 points")
                let brk: TimerMode = (sessionsCompleted % 4 == 0) ? .longBreak : .shortBreak
                change(to: brk)
            }
        } else {
            if settings.soundEnabled { sound.tone(660, 0.1); sound.tone(660, 0.1, delay: 0.2) }
            log("\(mode.label) complete")
            if seriesTarget > 1, seriesProgress < seriesTarget {
                notify("Break over! Next pomodoro starting…")
                change(to: .work)
                autoChain()
            } else {
                notify("Break over! Ready to focus?")
                change(to: .work)
            }
        }
    }

    /// Auto-advance the chain after a short delay when Chain Sessions is on.
    private func autoChain() {
        guard settings.autoSeriesEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.isRunning else { return }
            self.start()
        }
    }

    private func playCompletionMelody() {
        // Chord swell (A / C# / E)
        sound.tone(440.00, 0.5, amp: 0.18)
        sound.tone(554.37, 0.5, amp: 0.18)
        sound.tone(659.25, 0.5, amp: 0.18)
        // Descending run
        let run: [Double] = [440, 330, 262, 220]
        for (i, f) in run.enumerated() { sound.tone(f, 0.22, amp: 0.22, delay: 0.5 + Double(i) * 0.18) }
        // Low gong
        sound.tone(110, 0.8, amp: 0.3, delay: 1.3)
    }

    // MARK: Reminders ("Nudge Me")

    private func updateReminder() {
        reminderTicker?.cancel(); reminderTicker = nil
        idleSeconds = 0
        guard settings.reminderEnabled, !isRunning else { return }
        reminderTicker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.reminderTick() }
    }

    private func reminderTick() {
        guard settings.reminderEnabled, !isRunning else { return }
        idleSeconds += 1
        guard idleSeconds >= settings.reminderInterval * 60 else { return }
        idleSeconds = 0
        if settings.soundEnabled { sound.tone(880, 0.15); sound.tone(1100, 0.15, delay: 0.18) }
        notify("Time to focus! Start your pomodoro.")
        if settings.autoStartEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self, !self.isRunning else { return }
                self.start()
            }
        }
    }

    // MARK: Toast + log

    func notify(_ message: String) {
        toast = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { if self?.toast == message { self?.toast = nil } }
        }
    }

    private func log(_ message: String) {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        todayLog.insert(LogEntry(time: f.string(from: Date()), message: message), at: 0)
        if todayLog.count > 10 { todayLog = Array(todayLog.prefix(10)) }
        saveLog()
    }

    // MARK: Persistence

    private func load() {
        totalPoints = defaults.integer(forKey: "points")
        if defaults.string(forKey: "todayDate") == Self.todayKey() {
            todayCount = defaults.integer(forKey: "todayCount")
        }
        activityData = (defaults.dictionary(forKey: "activity") as? [String: Int]) ?? [:]
        if defaults.string(forKey: "logDate") == Self.todayKey(),
           let data = defaults.data(forKey: "log"),
           let entries = try? JSONDecoder().decode([LogEntry].self, from: data) {
            todayLog = entries
        }
    }

    private func save() {
        defaults.set(totalPoints, forKey: "points")
        defaults.set(Self.todayKey(), forKey: "todayDate")
        defaults.set(todayCount, forKey: "todayCount")
        defaults.set(activityData, forKey: "activity")
    }

    private func saveLog() {
        defaults.set(Self.todayKey(), forKey: "logDate")
        if let data = try? JSONEncoder().encode(todayLog) { defaults.set(data, forKey: "log") }
    }

    static func todayKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
