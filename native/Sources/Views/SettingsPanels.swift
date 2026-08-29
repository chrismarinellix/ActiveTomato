import SwiftUI

struct SettingsPanels: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var pro: ProStore
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
                if pro.isPro {
                    ToggleRow(title: "Voice Cues", isOn: $settings.voiceCuesEnabled)
                } else {
                    LockedRow(title: "Voice Cues") { pro.showPaywall = true }
                }
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
                if pro.isPro {
                    ToggleRow(title: "Chain Sessions (auto-advance)", isOn: $settings.autoSeriesEnabled)
                } else {
                    LockedRow(title: "Chain Sessions (auto-advance)") { pro.showPaywall = true }
                }
            }

            Panel(title: "PRO") {
                if pro.isPro {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.ink)
                        Text("Pro unlocked — thank you!")
                            .font(Theme.mono(11)).foregroundStyle(Theme.gray333)
                    }
                } else {
                    Button {
                        pro.showPaywall = true
                    } label: {
                        Text("Unlock ActiveTomato Pro — \(pro.product?.displayPrice ?? "$2.99")")
                            .font(Theme.mono(11, .medium))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    Task { await pro.restore() }
                } label: {
                    Text("Restore Purchases")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.gray666)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Panel(title: "DATA") {
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Text("Erase All Data")
                        .font(Theme.mono(11, .medium))
                        .foregroundStyle(Theme.errorRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog(
            "Erase all data? This permanently deletes your points, history, and synced data on all your Apple devices.",
            isPresented: $showDelete, titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                Task { await engine.deleteAllData() }
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

/// A settings row whose feature is Pro-gated; tapping opens the paywall.
private struct LockedRow: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(Theme.mono(11)).foregroundStyle(Theme.gray999)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 9))
                    Text("PRO").font(Theme.mono(9, .medium)).tracking(1)
                }
                .foregroundStyle(Theme.gray666)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 3))
            }
        }
        .buttonStyle(.plain)
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
