import Foundation

enum TimerMode: String, CaseIterable, Identifiable {
    case work, shortBreak, longBreak
    var id: String { rawValue }

    /// Full label shown above the digits.
    var label: String {
        switch self {
        case .work:       return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    /// Short label shown in the segmented mode tabs.
    var tab: String {
        switch self {
        case .work:       return "Focus"
        case .shortBreak: return "Short"
        case .longBreak:  return "Long"
        }
    }

    /// Hardcoded durations, matching the web app (not user-editable).
    var duration: Int {
        switch self {
        case .work:       return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak:  return 15 * 60
        }
    }
}

struct Level {
    let number: Int
    let title: String

    static func forPoints(_ points: Int) -> Level {
        switch points {
        case ..<100:  return Level(number: 1, title: "Seedling")
        case ..<300:  return Level(number: 2, title: "Sprout")
        case ..<600:  return Level(number: 3, title: "Sapling")
        case ..<1000: return Level(number: 4, title: "Tree")
        case ..<2000: return Level(number: 5, title: "Grove")
        default:      return Level(number: 6, title: "Forest")
        }
    }
}
