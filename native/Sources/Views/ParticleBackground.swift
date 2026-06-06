import SwiftUI

/// Calm drifting gray dust/star field (GPU-composited via Canvas),
/// approximating the web app's WebGL particle layer. Intensifies — more
/// brightness + size — while the timer runs.
struct ParticleBackground: View {
    var intense: Bool = false
    private let count = 150

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let s = Double(i)
                    let bx = frac(sin(s * 12.9898) * 43758.5453)
                    let by = frac(sin(s * 78.2330) * 43758.5453)
                    let depth = frac(sin(s * 4.531) * 9871.23)        // 0...1 parallax
                    let x = wrap(bx + (0.02 + depth * 0.03) * sin(t * 0.05 + s))
                    let y = wrap(by + (0.02 + depth * 0.03) * cos(t * 0.04 + s * 1.3) + t * 0.0012)
                    let twinkle = 0.5 + 0.5 * sin(t * 0.9 + s * 12.0)
                    let bright = depth > 0.93 ? 0.7 : 0.45            // a few brighter stars
                    let alpha = (intense ? 0.32 : 0.17) * (0.55 + 0.45 * twinkle) * (0.6 + depth * 0.6)
                    let r = (intense ? 1.9 : 1.2) * (0.6 + depth * 0.9) * (0.7 + 0.5 * twinkle)
                    let rect = CGRect(x: x * size.width, y: y * size.height, width: r, height: r)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(white: bright, opacity: alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func frac(_ v: Double) -> Double { v - floor(v) }
    private func wrap(_ v: Double) -> Double { let f = frac(v); return f < 0 ? f + 1 : f }
}
