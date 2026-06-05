import CloudKit

/// CloudKit private-database sync — the free Apple backend replacing Supabase.
/// Stores all app data in two records (app data + live timer state) in the
/// user's private iCloud database, so it backs up and syncs across the user's
/// Apple devices. Degrades silently to local-only when iCloud is unavailable.
@MainActor
final class CloudStore: ObservableObject {
    enum Status { case connecting, connected, error }
    @Published var status: Status = .connecting

    struct AppData {
        var points: Int
        var todayCount: Int
        var todayDate: String
        var activity: [String: Int]
    }
    struct TimerState {
        var mode: String
        var timeLeft: Int
        var isRunning: Bool
        var startedAt: Date?
        var seriesTarget: Int
        var seriesProgress: Int
    }

    private let container = CKContainer(identifier: "iCloud.com.activetomato.app")
    private var db: CKDatabase { container.privateCloudDatabase }
    private let appDataID = CKRecord.ID(recordName: "appdata")
    private let timerID = CKRecord.ID(recordName: "timerstate")

    func checkAccount() async {
        do {
            status = (try await container.accountStatus()) == .available ? .connected : .error
        } catch {
            status = .error
        }
    }

    // MARK: App data

    func saveAppData(_ data: AppData) async {
        let record = (try? await db.record(for: appDataID))
            ?? CKRecord(recordType: "AppData", recordID: appDataID)
        record["totalPoints"] = data.points as NSNumber
        record["todayCount"] = data.todayCount as NSNumber
        record["todayDate"] = data.todayDate as NSString
        if let json = try? JSONSerialization.data(withJSONObject: data.activity),
           let str = String(data: json, encoding: .utf8) {
            record["activityJSON"] = str as NSString
        }
        record["updatedAt"] = Date() as NSDate
        await persist(record)
    }

    func loadAppData() async -> AppData? {
        guard let r = try? await db.record(for: appDataID) else { return nil }
        var activity: [String: Int] = [:]
        if let str = r["activityJSON"] as? String,
           let data = str.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Int] {
            activity = dict
        }
        status = .connected
        return AppData(points: (r["totalPoints"] as? Int) ?? 0,
                       todayCount: (r["todayCount"] as? Int) ?? 0,
                       todayDate: (r["todayDate"] as? String) ?? "",
                       activity: activity)
    }

    // MARK: Timer state (cross-device)

    func saveTimerState(_ s: TimerState) async {
        let record = (try? await db.record(for: timerID))
            ?? CKRecord(recordType: "TimerState", recordID: timerID)
        record["mode"] = s.mode as NSString
        record["timeLeft"] = s.timeLeft as NSNumber
        record["isRunning"] = (s.isRunning ? 1 : 0) as NSNumber
        record["startedAt"] = (s.isRunning ? Date() : nil) as NSDate?
        record["seriesTarget"] = s.seriesTarget as NSNumber
        record["seriesProgress"] = s.seriesProgress as NSNumber
        record["updatedAt"] = Date() as NSDate
        await persist(record)
    }

    func loadTimerState() async -> TimerState? {
        guard let r = try? await db.record(for: timerID) else { return nil }
        return TimerState(mode: (r["mode"] as? String) ?? "work",
                          timeLeft: (r["timeLeft"] as? Int) ?? 0,
                          isRunning: ((r["isRunning"] as? Int) ?? 0) == 1,
                          startedAt: r["startedAt"] as? Date,
                          seriesTarget: (r["seriesTarget"] as? Int) ?? 1,
                          seriesProgress: (r["seriesProgress"] as? Int) ?? 0)
    }

    // MARK: Helper

    private func persist(_ record: CKRecord) async {
        do {
            try await db.save(record)
            status = .connected
        } catch {
            status = .error
        }
    }
}
