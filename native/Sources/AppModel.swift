import SwiftUI

/// Single owner of the app's long-lived objects, created once at launch.
@MainActor
final class AppModel: ObservableObject {
    let settings = AppSettings()
    let sound = SoundEngine()
    let cloud = CloudStore()
    let auth = AuthManager()
    let pro = ProStore()
    let engine: TimerEngine

    init() {
        engine = TimerEngine(settings: settings, sound: sound, cloud: cloud, pro: pro)
        // iCloud sync is a Pro feature; pull once when Pro unlocks.
        pro.onUnlock = { [weak self] in
            guard let self else { return }
            Task { await self.engine.pullFromCloud() }
        }
    }

    func bootstrap() async {
        await cloud.checkAccount()
        await engine.pullFromCloud()
    }
}
