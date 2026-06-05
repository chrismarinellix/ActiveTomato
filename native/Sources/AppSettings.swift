import SwiftUI

/// User preferences, mirroring the web app's `activetomato-preferences`.
/// Persisted to UserDefaults; each change saves immediately.
@MainActor
final class AppSettings: ObservableObject {
    @Published var soundEnabled: Bool          { didSet { save() } }
    @Published var intervalSoundEnabled: Bool  { didSet { save() } }
    @Published var beepInterval: Int           { didSet { save() } }   // minutes: 1 or 5
    @Published var tickSoundEnabled: Bool       { didSet { save() } }
    @Published var tickStyle: String           { didSet { save() } }   // soft/click/pulse/woodblock
    @Published var voiceCuesEnabled: Bool       { didSet { save() } }
    @Published var reminderEnabled: Bool        { didSet { reminderChanged?(); save() } }
    @Published var reminderInterval: Int        { didSet { reminderChanged?(); save() } } // 5/10/15/30/60
    @Published var autoStartEnabled: Bool       { didSet { save() } }
    @Published var autoSeriesEnabled: Bool      { didSet { save() } }
    @Published var systemVolume: Double         { didSet { save() } }  // 0...1

    /// Called when reminder settings change so the engine can reschedule.
    var reminderChanged: (() -> Void)?

    private static let key = "activetomato-preferences"

    init() {
        let d = UserDefaults.standard.dictionary(forKey: Self.key) ?? [:]
        soundEnabled         = d["soundEnabled"]         as? Bool   ?? true
        intervalSoundEnabled = d["intervalSoundEnabled"] as? Bool   ?? true
        beepInterval         = d["beepInterval"]         as? Int    ?? 5
        tickSoundEnabled     = d["tickSoundEnabled"]     as? Bool   ?? false
        tickStyle            = d["tickStyle"]            as? String ?? "soft"
        voiceCuesEnabled     = d["voiceCuesEnabled"]     as? Bool   ?? true
        reminderEnabled      = d["reminderEnabled"]      as? Bool   ?? false
        reminderInterval     = d["reminderInterval"]     as? Int    ?? 30
        autoStartEnabled     = d["autoStartEnabled"]     as? Bool   ?? false
        autoSeriesEnabled    = d["autoSeriesEnabled"]    as? Bool   ?? false
        systemVolume         = d["systemVolume"]         as? Double ?? 0.5
    }

    private func save() {
        UserDefaults.standard.set([
            "soundEnabled": soundEnabled,
            "intervalSoundEnabled": intervalSoundEnabled,
            "beepInterval": beepInterval,
            "tickSoundEnabled": tickSoundEnabled,
            "tickStyle": tickStyle,
            "voiceCuesEnabled": voiceCuesEnabled,
            "reminderEnabled": reminderEnabled,
            "reminderInterval": reminderInterval,
            "autoStartEnabled": autoStartEnabled,
            "autoSeriesEnabled": autoSeriesEnabled,
            "systemVolume": systemVolume,
        ], forKey: Self.key)
    }
}
