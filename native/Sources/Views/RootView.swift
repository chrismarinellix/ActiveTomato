import SwiftUI

struct RootView: View {
    @StateObject private var app = AppModel()

    var body: some View {
        ZStack {
            BackgroundView(engine: app.engine)
            ContentGate(app: app)
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

/// Switches between the Sign in with Apple screen and the main app.
private struct ContentGate: View {
    let app: AppModel
    @ObservedObject private var auth: AuthManager

    init(app: AppModel) {
        self.app = app
        _auth = ObservedObject(initialValue: app.auth)
    }

    var body: some View {
        if auth.isSignedIn {
            MainView(engine: app.engine, auth: app.auth)
        } else {
            AuthView(auth: app.auth)
        }
    }
}

#Preview {
    RootView()
}
