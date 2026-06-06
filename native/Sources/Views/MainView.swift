import SwiftUI

struct MainView: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var auth: AuthManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            EInkCard {
                VStack(spacing: 18) {
                    HeaderView(engine: engine, auth: auth)
                    Divider().overlay(Color.black.opacity(0.1))
                    SeriesSelector(engine: engine)
                    ModeTabs(engine: engine)
                    TimerDisplay(engine: engine)
                        .padding(.vertical, 6)
                    Controls(engine: engine)
                    Divider().overlay(Color.black.opacity(0.1)).padding(.top, 4)
                    ActivitySection(engine: engine)
                    SettingsPanels(engine: engine, settings: engine.settings, auth: auth)
                }
            }
            .padding(.vertical, 24)
        }
        .overlay(alignment: .top) {
            if let toast = engine.toast {
                Text(toast)
                    .font(Theme.mono(12, .medium))
                    .foregroundStyle(Theme.paper)
                    .padding(.horizontal, 18).padding(.vertical, 11)
                    .background(Theme.ink, in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: engine.toast)
    }
}
