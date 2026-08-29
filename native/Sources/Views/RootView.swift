import SwiftUI

struct RootView: View {
    @StateObject private var app = AppModel()

    var body: some View {
        ZStack {
            BackgroundView(engine: app.engine)
            // The app opens straight to the timer. Nothing here is account
            // based, so nothing may sit behind a login (guideline 5.1.1(v)).
            MainView(engine: app.engine)
                .environmentObject(app.pro)
        }
        .preferredColorScheme(.dark)
        .task { await app.bootstrap() }
    }
}

/// Dark gradient + drifting particles; intensifies while the timer runs.
private struct BackgroundView: View {
    @ObservedObject var engine: TimerEngine
    var body: some View {
        ZStack {
            Theme.pageGradient.ignoresSafeArea()
            ParticleBackground(intense: engine.isRunning).ignoresSafeArea()
        }
    }
}

#Preview {
    RootView()
}
