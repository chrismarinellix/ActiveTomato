import SwiftUI

/// One-time Pro unlock sheet, styled like the e-ink paper card.
struct PaywallView: View {
    @ObservedObject var pro: ProStore
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, detail: String)] = [
        ("link", "Chain Series", "Run 2x–6x pomodoros back to back"),
        ("square.grid.3x3.fill", "Activity & Levels", "Year grid, points, Seedling → Forest"),
        ("icloud.fill", "iCloud Sync", "Private sync across your Apple devices"),
        ("waveform", "Voice Cues", "Spoken session announcements"),
    ]

    var body: some View {
        ZStack {
            Theme.pageGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                EInkCard {
                    VStack(spacing: 22) {
                        VStack(spacing: 8) {
                            Text("ACTIVETOMATO PRO")
                                .font(Theme.display(18, .semibold))
                                .tracking(2)
                                .foregroundStyle(Theme.ink)
                            Text("One-time purchase. Yours forever.")
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.gray666)
                        }

                        Divider().overlay(Color.black.opacity(0.1))

                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(features, id: \.title) { f in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: f.icon)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.ink)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(f.title)
                                            .font(Theme.mono(12, .medium))
                                            .foregroundStyle(Theme.ink)
                                        Text(f.detail)
                                            .font(Theme.mono(10))
                                            .foregroundStyle(Theme.gray666)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            Button {
                                Task { await pro.purchase() }
                            } label: {
                                Text(pro.purchasing
                                     ? "…"
                                     : "Unlock — \(pro.product?.displayPrice ?? "$2.99")")
                                    .font(Theme.mono(13, .medium))
                                    .tracking(2)
                                    .foregroundStyle(Theme.paper)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.ink, in: RoundedRectangle(cornerRadius: 3))
                                    .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(pro.purchasing)

                            Button {
                                Task { await pro.restore() }
                            } label: {
                                Text("Restore Purchases")
                                    .font(Theme.mono(11))
                                    .foregroundStyle(Theme.gray666)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .disabled(pro.purchasing)

                            Button {
                                dismiss()
                            } label: {
                                Text("Not now")
                                    .font(Theme.mono(11))
                                    .foregroundStyle(Theme.gray999)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("The single pomodoro timer is free forever.")
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.gray999)
                    }
                }
                .padding(.vertical, 24)
            }
        }
    }
}

#Preview {
    PaywallView(pro: ProStore())
}
