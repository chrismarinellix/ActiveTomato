import SwiftUI
import Combine

/// Core pomodoro state machine. Phase 1: fully working locally
/// (countdown, modes, series/chain, points, levels, completion flow).
/// CloudKit sync is layered on in Phase 3.
@MainActor
final class TimerEngine: ObservableObject {
    @Published var mode: TimerMode = .work
    @Published var timeLeft: Int = TimerMode.work.duration
    @Published var isRunning = false

    @Published var totalPoints = 0
    @Published var todayCount = 0

    @Published var seriesTarget = 1      // 1 = "Single", 2...6 = chain length
    @Published var seriesProgress = 0
    @Published var sessionsCompleted = 0

    @Published var toast: String? = nil

    private var ticker: AnyCancellable?
    private let defaults = UserDefaults.standard

    init() { load() }

    // MARK: Derived

    var duration: Int { mode.duration }

    /// 0...100
    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(duration - timeLeft) / Double(duration) * 100
    }

    var level: Level { Level.forPoints(totalPoints) }
    var isWarning: Bool { timeLeft <= 60 && isRunning }
    var elapsedMinutes: Int { (duration - timeLeft) / 60 }

    var timeString: String {
        String(format: "%02d:%02d", timeLeft / 60, timeLeft % 60)
    }

    // MARK: Controls

    func start() {
        guard !isRunning else { return }
        isRunning = true
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
    }

    func toggle() { isRunning ? pause() : start() }

    func reset() {
        pause()
        timeLeft = duration
    }

    func change(to newMode: TimerMode) {
        pause()
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
        if timeLeft == 0 { complete() }
    }

    private func complete() {
        pause()
        if mode == .work {
            totalPoints += 25
            todayCount += 1
            sessionsCompleted += 1
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
                }
            } else {
                notify("Pomodoro complete! +25 points")
                let brk: TimerMode = (sessionsCompleted % 4 == 0) ? .longBreak : .shortBreak
                change(to: brk)
            }
        } else {
            notify("Break over! Ready to focus?")
            change(to: .work)
        }
    }

    func notify(_ message: String) {
        toast = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                if self?.toast == message { self?.toast = nil }
            }
        }
    }

    // MARK: Local persistence (Phase 1)

    private func load() {
        totalPoints = defaults.integer(forKey: "points")
        let savedDay = defaults.string(forKey: "todayDate")
        if savedDay == Self.todayKey() {
            todayCount = defaults.integer(forKey: "todayCount")
        } else {
            todayCount = 0
        }
    }

    private func save() {
        defaults.set(totalPoints, forKey: "points")
        defaults.set(Self.todayKey(), forKey: "todayDate")
        defaults.set(todayCount, forKey: "todayCount")
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
