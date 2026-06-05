import SwiftUI

/// Calm drifting gray dust/star field, approximating the web app's
/// WebGL/WebGPU particle layer. Intensifies (brighter, larger) while running.
struct ParticleBackground: View {
    var intense: Bool = false
    private let count = 110

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let s = Double(i)
                    let bx = frac(sin(s * 12.9898) * 43758.5453)
                    let by = frac(sin(s * 78.2330) * 43758.5453)
                    let x = wrap(bx + 0.03 * sin(t * 0.05 + s))
                    let y = wrap(by + 0.03 * cos(t * 0.04 + s * 1.3) + t * 0.0015)
                    let pulse = 0.5 + 0.5 * sin(t * 0.8 + s)
                    let alpha = (intense ? 0.30 : 0.16) * (0.6 + 0.4 * pulse)
                    let r = (intense ? 1.9 : 1.2) * (0.7 + 0.5 * pulse)
                    let rect = CGRect(x: x * size.width, y: y * size.height, width: r, height: r)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.45, opacity: alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func frac(_ v: Double) -> Double { v - floor(v) }
    private func wrap(_ v: Double) -> Double { let f = frac(v); return f < 0 ? f + 1 : f }
}
