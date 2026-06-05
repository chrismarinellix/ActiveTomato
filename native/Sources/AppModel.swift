import SwiftUI

/// Single owner of the app's long-lived objects, created once at launch.
@MainActor
final class AppModel: ObservableObject {
    let settings = AppSettings()
    let sound = SoundEngine()
    let cloud = CloudStore()
    let auth = AuthManager()
    let engine: TimerEngine

    init() {
        engine = TimerEngine(settings: settings, sound: sound, cloud: cloud)
    }

    func bootstrap() async {
        await cloud.checkAccount()
        await engine.pullFromCloud()
    }
}
