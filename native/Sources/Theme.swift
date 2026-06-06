import SwiftUI

/// Color + type tokens lifted verbatim from the e-ink web app.
enum Theme {
    static let ink       = Color(hex: 0x1A1A1A)   // primary ink / active fills
    static let inkDark   = Color(hex: 0x0A0A0A)   // darkest (digits)
    static let paper     = Color(hex: 0xF5F5F0)   // e-ink card surface
    static let gray333   = Color(hex: 0x333333)
    static let gray555   = Color(hex: 0x555555)
    static let gray666   = Color(hex: 0x666666)
    static let gray888   = Color(hex: 0x888888)
    static let gray999   = Color(hex: 0x999999)
    static let syncGreen = Color(hex: 0x44AA44)
    static let syncRed   = Color(hex: 0xAA4444)
    static let syncAmber = Color(hex: 0xAAAA44)
    static let errorRed  = Color(hex: 0xCC0000)

    // Dark page background gradient (#0a0a0a -> #151515 -> #0a0a0a, 135deg)
    static let pageGradient = LinearGradient(
        colors: [Color(hex: 0x0A0A0A), Color(hex: 0x151515), Color(hex: 0x0A0A0A)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// UI / body / controls — IBM Plex Mono (matches the web app).
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black: name = "IBMPlexMono-Medium"
        default: name = "IBMPlexMono-Regular"
        }
        return .custom(name, size: size)
    }

    /// Headings / digits / stat values — JetBrains Mono.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black:   name = "JetBrainsMono-Bold"
        case .semibold, .medium:      name = "JetBrainsMono-SemiBold"
        default:                      name = "JetBrainsMono-Regular"
        }
        return .custom(name, size: size)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}
