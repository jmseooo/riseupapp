import SwiftUI

// MARK: - Color

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        self.init(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >>  8) & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }

    // ── Core palette ──────────────────────────────────────────────────────
    static let rBlackWarm     = Color(hex: "#383D39")
    static let rCream         = Color(hex: "#FFFAF3")
    static let rGreenAccent   = Color(hex: "#9DCD7B")
    static let rGreenBright   = Color(hex: "#B0F28A")
    static let rBrown         = Color(hex: "#C8734A")
    static let rOrange        = Color(hex: "#FF7A3D")

    // ── Text ──────────────────────────────────────────────────────────────
    static let rTextPrimary   = Color(hex: "#1A1714")
    static let rTextBody      = Color(hex: "#383D39")
    static let rTextSub       = Color(hex: "#9E9A90")
    static let rTextMuted     = Color(hex: "#9BA39C")
    static let rTextDisabled  = Color(hex: "#BCBCBC")
    static let rTextWarm      = Color(hex: "#C9C1B4")
    static let rTextGray      = Color(hex: "#6A6A6A")

    // ── Surface ───────────────────────────────────────────────────────────
    static let rSurfaceGlass  = Color.white.opacity(0.30)
    static let rSurfaceFrost  = Color.white.opacity(0.80)
    static let rDivider       = Color(hex: "#1A1714").opacity(0.15)
    static let rBorder        = Color(hex: "#1A1714").opacity(0.08)
    static let rSurfaceInput  = Color(hex: "#F8F8F8")
}

// MARK: - Shadow helpers

extension View {
    func cardShadow() -> some View {
        self
            .shadow(color: Color(hex: "#1A1714").opacity(0.04), radius:  1, x: 0, y: 1)
            .shadow(color: Color(hex: "#1A1714").opacity(0.06), radius: 12, x: 0, y: 8)
    }
}

// MARK: - Font
// Requires font files added to the Xcode target and Info.plist entries.
// Family names must match the PostScript name in each .ttf/.otf file.

extension Font {
    static func radioCanadaBig(_ size: CGFloat) -> Font {
        .custom("RadioCanadaBig-SemiBold", size: size)
    }
    static func rajdhani(_ size: CGFloat) -> Font {
        .custom("Rajdhani-SemiBold", size: size)
    }
    static func prompt(_ size: CGFloat, weight: PromptWeight = .regular) -> Font {
        .custom("Prompt-\(weight.rawValue)", size: size)
    }
    static func pretendard(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("PretendardVariable", size: size).weight(weight)
    }
    static func akiraExpanded(_ size: CGFloat) -> Font {
        .custom("AkiraExpanded-SuperBold", size: size)
    }

    enum PromptWeight: String {
        case regular  = "Regular"
        case medium   = "Medium"
        case semiBold = "SemiBold"
    }
}

// MARK: - Spacing & Radius constants

enum DS {
    static let hPad:      CGFloat = 24
    static let cardRadius:CGFloat = 22
    static let pillRadius:CGFloat = 90
    static let navH:      CGFloat = 53
    static let btnH:      CGFloat = 66
}
