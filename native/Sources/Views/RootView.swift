import SwiftUI

struct RootView: View {
    @StateObject private var engine = TimerEngine(settings: AppSettings(), sound: SoundEngine())

    var body: some View {
        ZStack {
            Theme.pageGradient.ignoresSafeArea()
            ParticleBackground(intense: engine.isRunning).ignoresSafeArea()
            MainView(engine: engine)
                .padding(.horizontal, 8)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
