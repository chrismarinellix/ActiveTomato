import SwiftUI

// MARK: - E-ink card chrome

/// Cream paper panel with the concentric dark bezel + soft drop shadow.
struct EInkCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .padding(7)
            .background(Theme.ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .padding(2)
            .background(Theme.inkDark.opacity(0.95), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .shadow(color: .black.opacity(0.45), radius: 40, x: 0, y: 24)
    }
}

// MARK: - Header

struct HeaderView: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var auth: AuthManager
    @ObservedObject var cloud: CloudStore

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVETOMATO")
                    .font(Theme.display(16, .semibold))
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    if let name = auth.displayName {
                        Text(name).font(Theme.mono(10)).foregroundStyle(Theme.gray666)
                    }
                    Button("Logout") { auth.signOut() }
                        .font(Theme.mono(9))
                        .tracking(1)
                        .foregroundStyle(Theme.gray666)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.2), lineWidth: 1))
                        .buttonStyle(.plain)
                    SyncIndicator(state: syncState)
                }
            }
            Spacer()
            HStack(spacing: 18) {
                StatBox(label: "POINTS", value: "\(engine.totalPoints)")
                StatBox(label: "TODAY", value: "\(engine.todayCount)")
                VStack(alignment: .trailing, spacing: 4) {
                    Text("LEVEL").font(Theme.mono(9)).tracking(1).foregroundStyle(Theme.gray999)
                    Text(engine.level.title)
                        .font(Theme.display(10, .semibold))
                        .tracking(1)
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(Theme.paper)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 3))
                }
            }
        }
    }

    private var syncState: SyncIndicator.State {
        switch cloud.status {
        case .connecting: return .connecting
        case .connected:  return .connected
        case .error:      return .error
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(label).font(Theme.mono(9)).tracking(1).fixedSize()
                .foregroundStyle(Theme.gray999)
            Text(value).font(Theme.display(20, .semibold)).foregroundStyle(Theme.ink)
        }
    }
}

struct SyncIndicator: View {
    enum State { case local, connecting, connected, error }
    let state: State

    private var text: String {
        switch state {
        case .local:      return "Local"
        case .connecting: return "..."
        case .connected:  return "Synced"
        case .error:      return "Offline"
        }
    }
    private var color: Color {
        switch state {
        case .local:      return Theme.gray888
        case .connecting: return Theme.syncAmber
        case .connected:  return Theme.syncGreen
        case .error:      return Theme.syncRed
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(Theme.mono(10)).foregroundStyle(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Series / Chain selector

struct SeriesSelector: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("CHAIN").font(Theme.mono(10)).tracking(1).fixedSize()
                    .foregroundStyle(Theme.gray666)
                ForEach(1...6, id: \.self) { n in
                    Button {
                        engine.setSeries(n)
                    } label: {
                        Text(n == 1 ? "Single" : "\(n)x")
                            .font(Theme.mono(11))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(engine.seriesTarget == n ? Theme.paper : Theme.gray666)
                            .padding(.horizontal, 9).padding(.vertical, 6)
                            .background(
                                engine.seriesTarget == n ? Theme.ink : Color.clear,
                                in: RoundedRectangle(cornerRadius: 3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            if engine.seriesTarget > 1 {
                SeriesDots(engine: engine)
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 3))
    }
}

struct SeriesDots: View {
    @ObservedObject var engine: TimerEngine
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<engine.seriesTarget, id: \.self) { i in
                if i > 0 {
                    Circle()
                        .fill(i <= engine.seriesProgress ? Theme.gray666 : Color.black.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
                workDot(index: i)
            }
        }
    }

    @ViewBuilder private func workDot(index i: Int) -> some View {
        let completed = i < engine.seriesProgress
        let current = i == engine.seriesProgress
        Circle()
            .strokeBorder(current ? Theme.ink : .clear, lineWidth: 2)
            .background(Circle().fill(completed ? Theme.ink : Color.black.opacity(0.1)))
            .frame(width: 10, height: 10)
    }
}

// MARK: - Mode tabs

struct ModeTabs: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(TimerMode.allCases.enumerated()), id: \.element.id) { idx, m in
                if idx > 0 { Rectangle().fill(Color.black.opacity(0.15)).frame(width: 1) }
                Button {
                    engine.change(to: m)
                } label: {
                    Text(m.tab.uppercased())
                        .font(Theme.mono(12))
                        .tracking(2)
                        .foregroundStyle(engine.mode == m ? Theme.paper : Theme.gray555)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(engine.mode == m ? Theme.ink : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.15), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Timer display

struct TimerDisplay: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        VStack(spacing: 14) {
            Text(engine.mode.label.uppercased())
                .font(Theme.mono(13))
                .tracking(3)
                .foregroundStyle(Theme.gray888)

            Text(engine.timeString)
                .font(Theme.display(96, .bold))
                .tracking(-4)
                .foregroundStyle(Theme.inkDark)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .modifier(BlinkModifier(active: engine.isWarning))

            // Thin horizontal progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.08))
                    Capsule().fill(Theme.ink)
                        .frame(width: geo.size.width * engine.progress / 100)
                        .animation(.linear(duration: 1), value: engine.progress)
                }
            }
            .frame(height: 4)
            .frame(maxWidth: 600)

            if engine.mode == .work && engine.isRunning {
                Text("\(engine.elapsedMinutes) min elapsed")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.gray999)
            }
        }
    }
}

/// Blinks its content (opacity 1 <-> 0.4) while `active`, matching the
/// last-60-seconds warning animation on the web digits.
struct BlinkModifier: ViewModifier {
    let active: Bool
    @State private var dim = false

    func body(content: Content) -> some View {
        content
            .opacity(active && dim ? 0.4 : 1)
            .animation(active ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                       value: dim)
            .onChange(of: active) { _, now in dim = now }
            .onAppear { dim = active }
    }
}

// MARK: - Controls

struct Controls: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 14) {
            Button {
                engine.toggle()
            } label: {
                Text(engine.isRunning ? "Pause" : "Start")
                    .font(Theme.mono(13, .medium))
                    .tracking(3)
                    .foregroundStyle(Theme.paper)
                    .padding(.vertical, 14).padding(.horizontal, 44)
                    .background(Theme.ink, in: RoundedRectangle(cornerRadius: 3))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            Button {
                engine.reset()
            } label: {
                Text("Reset")
                    .font(Theme.mono(13, .medium))
                    .tracking(3)
                    .foregroundStyle(Theme.ink)
                    .padding(.vertical, 14).padding(.horizontal, 32)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}
