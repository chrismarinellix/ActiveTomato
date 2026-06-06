import SwiftUI

struct SettingsPanels: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: AppSettings
    @ObservedObject var auth: AuthManager
    @State private var showDelete = false

    var body: some View {
        VStack(spacing: 12) {
            Panel(title: "AUDIO CUES") {
                ToggleRow(title: "Completion Sound", isOn: $settings.soundEnabled)
                ToggleRow(title: "Progress Beeps", isOn: $settings.intervalSoundEnabled)
                if settings.intervalSoundEnabled {
                    MenuRow(title: "Beep every", value: $settings.beepInterval,
                            options: [(1, "1 min"), (5, "5 min")])
                }
                ToggleRow(title: "Countdown Tick", isOn: $settings.tickSoundEnabled)
                if settings.tickSoundEnabled {
                    MenuRow(title: "Tick style", value: $settings.tickStyle,
                            options: [("soft", "Soft"), ("click", "Click"),
                                      ("pulse", "Pulse"), ("woodblock", "Woodblock")])
                }
                ToggleRow(title: "Voice Cues", isOn: $settings.voiceCuesEnabled)
                HStack {
                    Text("Volume").font(Theme.mono(11)).foregroundStyle(Theme.gray333)
                    Slider(value: $settings.systemVolume, in: 0...1)
                        .tint(Theme.ink)
                        .onChange(of: settings.systemVolume) { _, v in engine.sound.masterVolume = v }
                }
            }

            Panel(title: "NUDGE ME") {
                ToggleRow(title: "Remind to Focus", isOn: $settings.reminderEnabled)
                if settings.reminderEnabled {
                    MenuRow(title: "Every", value: $settings.reminderInterval,
                            options: [(5, "5 min"), (10, "10 min"), (15, "15 min"),
                                      (30, "30 min"), (60, "60 min")])
                    ToggleRow(title: "Auto-Start on reminder", isOn: $settings.autoStartEnabled)
                }
            }

            Panel(title: "CHAIN MODE") {
                ToggleRow(title: "Chain Sessions (auto-advance)", isOn: $settings.autoSeriesEnabled)
            }

            Panel(title: "ACCOUNT") {
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Text("Delete Account")
                        .font(Theme.mono(11, .medium))
                        .foregroundStyle(Theme.errorRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog(
            "Delete your account? This permanently erases your points, history, and synced data on all your Apple devices.",
            isPresented: $showDelete, titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                Task {
                    await engine.deleteAllData()
                    auth.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Building blocks

private struct Panel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Theme.mono(10)).tracking(2).foregroundStyle(Theme.gray666)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(Theme.mono(11)).foregroundStyle(Theme.gray333)
        }
        .tint(Theme.ink)
    }
}

private struct MenuRow<T: Hashable>: View {
    let title: String
    @Binding var value: T
    let options: [(T, String)]

    private var currentLabel: String { options.first { $0.0 == value }?.1 ?? "" }

    var body: some View {
        HStack {
            Text(title).font(Theme.mono(11)).foregroundStyle(Theme.gray333)
            Spacer()
            Menu {
                ForEach(options, id: \.0) { opt in
                    Button(opt.1) { value = opt.0 }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentLabel).font(Theme.mono(11, .medium))
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 8))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 3))
            }
        }
    }
}
