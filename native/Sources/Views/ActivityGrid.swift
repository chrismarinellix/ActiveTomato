import SwiftUI

/// GitHub-style contribution grid (monochrome) + today's log.
struct ActivitySection: View {
    @ObservedObject var engine: TimerEngine
    private let weeks = 17
    private let rows = 7

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACTIVITY").font(Theme.mono(11)).tracking(2).foregroundStyle(Theme.gray666)
                Spacer()
                Text("\(engine.yearTotal) pomodoros this year")
                    .font(Theme.mono(10)).foregroundStyle(Theme.gray999)
            }

            Canvas { ctx, size in
                let gap = 2.0
                let cell = (size.width - gap * Double(weeks - 1)) / Double(weeks)
                for col in 0..<weeks {
                    for row in 0..<rows {
                        let rect = CGRect(x: Double(col) * (cell + gap),
                                          y: Double(row) * (cell + gap),
                                          width: cell, height: cell)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 1),
                                 with: .color(color(col: col, row: row)))
                    }
                }
            }
            .aspectRatio(CGFloat(weeks) / CGFloat(rows), contentMode: .fit)
            .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Text("Less").font(Theme.mono(9)).foregroundStyle(Theme.gray999)
                ForEach(0..<5, id: \.self) { l in
                    RoundedRectangle(cornerRadius: 1).fill(shade(level: l, isToday: false))
                        .frame(width: 9, height: 9)
                }
                Text("More").font(Theme.mono(9)).foregroundStyle(Theme.gray999)
            }

            if !engine.todayLog.isEmpty {
                Divider().overlay(Color.black.opacity(0.08)).padding(.top, 4)
                Text("TODAY'S LOG").font(Theme.mono(10)).tracking(2).foregroundStyle(Theme.gray666)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(engine.todayLog) { entry in
                        HStack(spacing: 8) {
                            Text(entry.time).font(Theme.mono(10)).foregroundStyle(Theme.gray999)
                            Text(entry.message).font(Theme.mono(10)).foregroundStyle(Theme.gray555)
                        }
                    }
                }
            }
        }
    }

    // MARK: Date / color math

    private func dateFor(col: Int, row: Int) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekdayToday = cal.component(.weekday, from: today) - 1   // 0 = Sunday
        let daysBack = weekdayToday + (weeks - 1) * 7
        guard let start = cal.date(byAdding: .day, value: -daysBack, to: today) else { return nil }
        return cal.date(byAdding: .day, value: col * 7 + row, to: start)
    }

    private func color(col: Int, row: Int) -> Color {
        guard let date = dateFor(col: col, row: row), date <= Calendar.current.startOfDay(for: Date()) else {
            return Color.black.opacity(0.05)
        }
        let key = Self.keyFormatter.string(from: date)
        let count = engine.activityData[key] ?? 0
        let isToday = key == TimerEngine.todayKey()
        let level = count == 0 ? 0 : count >= 8 ? 4 : count >= 5 ? 3 : count >= 3 ? 2 : 1
        return shade(level: level, isToday: isToday)
    }

    private func shade(level: Int, isToday: Bool) -> Color {
        let normal: [Double]  = [0.05, 0.12, 0.22, 0.35, 0.55]
        let today: [Double]   = [0.15, 0.18, 0.28, 0.42, 0.65]
        return Color.black.opacity((isToday ? today : normal)[level])
    }
}
