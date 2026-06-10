import SwiftUI
import Foundation

// MARK: - Seeded RNG

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) | 1
    }

    mutating func next() -> UInt64 {
        var x = state
        x ^= x << 13
        x ^= x >> 7
        x ^= x << 17
        state = x
        return x
    }
}

// MARK: - OrbDefinition

struct OrbDefinition {
    let sizePercent: Double   // diameter as % of frame width
    let startColor: Color
    let endColor: Color
}

// MARK: - BlobParams

struct BlobParams {
    let xPercent: Double
    let yPercent: Double
    let sizePercent: Double
    let startColor: Color
    let endColor: Color
    let animationDelay: Double
}

// MARK: - WeatherBaseTheme

struct WeatherBaseTheme {
    let id: String
    let isDark: Bool
    let backgroundStart: Color
    let backgroundEnd: Color
    let backgroundAngle: Double
    let orbs: [OrbDefinition]

    // Per-theme visual baseline (weather data modulates around these)
    let baseBlurRadius: CGFloat     // 20–120
    let baseOrbOpacity: Double      // 0.05–0.75
    let baseAnimDuration: Double    // seconds per drift cycle — lower = faster
    let turbulence: Double          // 0.0 = smooth path, 1.0 = chaotic jitter
    let pulseEnabled: Bool          // opacity pulsing (storms)
    let blobCountRange: ClosedRange<Int>
}

// MARK: - WeatherVisualParams

struct WeatherVisualParams {
    let theme: WeatherBaseTheme
    let blurRadius: CGFloat
    let orbOpacity: Double
    let animationDuration: Double
    let displacementPercent: Double
    let brightnessScale: Double
    let saturationScale: Double
    let hueOffset: Double
    let turbulence: Double
    let pulseEnabled: Bool
    let blobs: [BlobParams]
    let gradientAngleOffset: Double
    // 시간대 색온도 오버레이 (WMO 0,1 제외)
    let nightOverlayColor: Color
    let nightOverlayOpacity: Double
}

// MARK: - WeatherThemeLibrary

struct WeatherThemeLibrary {

    private static func c(_ hex: String) -> Color {
        var n: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&n)
        return Color(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >>  8) & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }

    private static func orb(size: Double, _ s: String, _ e: String) -> OrbDefinition {
        OrbDefinition(sizePercent: size, startColor: c(s), endColor: c(e))
    }

    private static func makeTheme(
        _ id: String, dark: Bool = false, angle: Double,
        bg s: String, _ e: String,
        orbs: [OrbDefinition],
        blur: CGFloat, opacity: Double, dur: Double,
        turb: Double = 0.0, pulse: Bool = false,
        count: ClosedRange<Int>
    ) -> WeatherBaseTheme {
        WeatherBaseTheme(
            id: id, isDark: dark,
            backgroundStart: c(s), backgroundEnd: c(e),
            backgroundAngle: angle, orbs: orbs,
            baseBlurRadius: blur, baseOrbOpacity: opacity,
            baseAnimDuration: dur, turbulence: turb,
            pulseEnabled: pulse, blobCountRange: count
        )
    }

    // MARK: Theme Catalog

    static let allThemes: [String: WeatherBaseTheme] = [

        // ── Atmosphere ─────────────────────────────────────────────────────

        // 새벽: 해 뜨기 전 어스름한 블루-라벤더. 채도 낮고 차분한 pre-dawn 느낌.
        "sunrise": makeTheme("sunrise", angle: 200, bg: "D8E2F0", "C4D0E8", orbs: [
            orb(size: 155, "7888C8", "5C70B8"),
            orb(size: 100, "9C80CC", "7C64BC"),
            orb(size:  70, "D0AAAA", "B89090"),
        ], blur: 38, opacity: 0.48, dur: 28, turb: 0.0, count: 3...5),

        // 구 새벽 (웜): 기존 오렌지-코랄 톤. 비교·실험용.
        "sunrise-warm": makeTheme("sunrise-warm", angle: 180, bg: "F8F1E8", "FCEFE0", orbs: [
            orb(size: 160, "FF9582", "F89383"),
            orb(size: 105, "FFB893", "FA9F7A"),
            orb(size:  65, "FFE2A0", "FFCE78"),
        ], blur: 35, opacity: 0.50, dur: 28, turb: 0.0, count: 3...5),

        // 맑은 낮: 선명한 골든 옐로우 + 스카이블루. 새벽보다 뚜렷하게 채도 높음.
        "clear-day": makeTheme("clear-day", angle: 180, bg: "FFF8E0", "FFF0C0", orbs: [
            orb(size: 155, "FFD040", "F0B820"),
            orb(size:  90, "68C4F8", "48A8F0"),
            orb(size:  65, "FFB840", "F09820"),
            orb(size:  50, "FFE888", "F8D040"),
        ], blur: 22, opacity: 0.55, dur: 25, turb: 0.0, count: 4...7),

        // Warm/cool contrast — slightly faster, subtle turbulence.
        "partly-cloudy": makeTheme("partly-cloudy", angle: 165, bg: "F2F5F9", "E8EDF4", orbs: [
            orb(size: 145, "BCD2EE", "98B8E0"),
            orb(size:  90, "FFC598", "F5A572"),
            orb(size:  60, "F0E5DC", "DECBB8"),
        ], blur: 40, opacity: 0.45, dur: 20, turb: 0.1, count: 4...7),

        // Lavender + pink contrast — fast drift, distinct orbs clearly visible.
        "cloudy": makeTheme("cloudy", angle: 175, bg: "F4F2FA", "ECEAF4", orbs: [
            orb(size: 160, "C8B4EC", "A89CD8"),  // soft violet/lavender
            orb(size: 105, "ECC0D4", "D4A0BC"),  // dusty pink/rose
            orb(size:  80, "B8C4F0", "98AADC"),  // periwinkle blue
            orb(size:  58, "E0D0F0", "C8B8DC"),  // light purple accent
        ], blur: 36, opacity: 0.72, dur: 7, turb: 0.3, count: 4...7),

        // Heavy, slow — blobs barely move. Oppressive ceiling feel.
        "overcast": makeTheme("overcast", angle: 195, bg: "F1E8E8", "E2D2D5", orbs: [
            orb(size: 145, "E4B0B8", "C68C9A"),
            orb(size:  90, "E0B8C0", "C292A0"),
            orb(size:  60, "F0E0DC", "DAC2BA"),
        ], blur: 65, opacity: 0.60, dur: 14, turb: 0.2, count: 4...8),

        // ── Precipitation ──────────────────────────────────────────────────

        // Gentle, melancholy blue — slow drift, soft blur.
        "drizzle": makeTheme("drizzle", angle: 210, bg: "F0F4F8", "E2EAF2", orbs: [
            orb(size: 150, "B0C8E2", "88A8CC"),
            orb(size:  70, "C2BCE2", "9F98CC"),
        ], blur: 50, opacity: 0.55, dur: 12, turb: 0.3, count: 3...6),

        // Darker blue, medium-fast — falling feeling, noticeable turbulence.
        "rain": makeTheme("rain", dark: true, angle: 175, bg: "4A82CC", "EEF3F8", orbs: [
            orb(size: 165, "6B95DD", "4A78C8"),
            orb(size: 110, "8B9DE8", "6F7BD3"),
            orb(size:  70, "E5ECF6", "C8D8EC"),
        ], blur: 45, opacity: 0.60, dur: 9, turb: 0.5, count: 4...8),

        // Fast, compressed — blobs feel trapped. Shower bursts.
        "showers": makeTheme("showers", angle: 135, bg: "F0F5F8", "D8E5EE", orbs: [
            orb(size: 145, "92BFDB", "6FA5D2"),
            orb(size: 115, "A2D2C5", "80BCAE"),
            orb(size:  70, "A2C2D5", "7FA9C5"),
        ], blur: 45, opacity: 0.55, dur: 8, turb: 0.5, count: 3...7),

        // Dark, chaotic, pulsing — highest turbulence. pulseEnabled.
        "thunderstorm": makeTheme("thunderstorm", dark: true, angle: 155, bg: "3D335E", "D8A07A", orbs: [
            orb(size: 155, "6B4FB0", "4A2F88"),
            orb(size: 115, "B582CC", "8E5DAE"),
            orb(size:  95, "FFC596", "ECA876"),
            orb(size:  60, "7A5CB0", "5A4290"),
        ], blur: 44, opacity: 0.80, dur: 1.8, turb: 0.9, pulse: true, count: 3...5),

        // Pale, dreamy — slow float, many small blobs like falling flakes.
        "snow": makeTheme("snow", angle: 180, bg: "F4F8FB", "E5EEF4", orbs: [
            orb(size: 150, "FAFCFE", "DEE9F2"),
            orb(size:  75, "C8D8E8", "A2B8D0"),
            orb(size:  60, "E5EEF6", "BFD2E2"),
            orb(size:  90, "FAFCFE", "D8E5F0"),
            orb(size:  50, "D5E2EC", "B0C5DA"),
        ], blur: 30, opacity: 0.45, dur: 22, turb: 0.1, count: 5...10),

        // Aggressive pale — fast, turbulent, compressed like a blizzard wall.
        "blizzard": makeTheme("blizzard", angle: 190, bg: "DCE6F2", "B5C8DE", orbs: [
            orb(size: 160, "C2D5EC", "94B0D2"),
            orb(size:  90, "DCE6F2", "B2C5DC"),
            orb(size:  65, "C8D2E2", "A2B0C8"),
        ], blur: 35, opacity: 0.55, dur: 8, turb: 0.7, count: 4...8),

        // ── Visibility ─────────────────────────────────────────────────────

        // 2–4 massive blobs covering screen, near-zero movement.
        "mist": makeTheme("mist", angle: 200, bg: "F5F2F8", "EAE5F0", orbs: [
            orb(size: 155, "F0BCD2", "DA9CBC"),
            orb(size: 110, "BFB2E0", "9C90CE"),
            orb(size:  70, "F0E5D8", "DACFC0"),
        ], blur: 90, opacity: 0.70, dur: 40, turb: 0.0, count: 2...4),

        // Warmer than mist — slightly more visible, amber haze.
        "hazy": makeTheme("hazy", angle: 215, bg: "FCF3E5", "F5DEBD", orbs: [
            orb(size: 150, "FFCC92", "F6AC68"),
            orb(size: 105, "FCB8AC", "EF9080"),
            orb(size:  70, "FFDDA8", "F8C078"),
        ], blur: 75, opacity: 0.65, dur: 35, turb: 0.0, count: 3...5),

        // Grey-brown, heavy opacity — barely moves. Smoke column feel.
        "smoke": makeTheme("smoke", angle: 220, bg: "F8F0E2", "EDDFC8", orbs: [
            orb(size: 150, "F0D4A8", "D2B58A"),
            orb(size: 100, "F5E8D0", "DCC8A2"),
            orb(size:  60, "EAC8C2", "D2A4A0"),
        ], blur: 85, opacity: 0.70, dur: 38, turb: 0.0, count: 2...4),

        // Sandy brown — medium drift, moderate turbulence.
        "dust": makeTheme("dust", dark: true, angle: 160, bg: "D2BC95", "B59872", orbs: [
            orb(size: 145, "E8C58E", "C8A565"),
            orb(size: 100, "D5AC78", "B08856"),
            orb(size:  95, "DEB46E", "BE9050"),
            orb(size:  60, "A88752", "8E6D38"),
        ], blur: 60, opacity: 0.60, dur: 18, turb: 0.3, count: 3...6),

        // ── Special ────────────────────────────────────────────────────────

        // Intense sand — fast, high turbulence. Wall of dust.
        "sandstorm": makeTheme("sandstorm", dark: true, angle: 0, bg: "C2A57E", "9E7E50", orbs: [
            orb(size: 155, "E8C586", "C8A065"),
            orb(size:  95, "C8986F", "A0764C"),
            orb(size: 115, "8E6442", "6E4A28"),
        ], blur: 55, opacity: 0.65, dur: 10, turb: 0.8, count: 3...5),

        // Bright but moving — fast turbulent drift.
        "windy": makeTheme("windy", angle: 45, bg: "F0F5F2", "DCE8E0", orbs: [
            orb(size: 155, "BCDDC8", "9CCEB5"),
            orb(size: 115, "EDE48E", "DCCF6E"),
            orb(size:  85, "B5D2D8", "88B2BC"),
        ], blur: 35, opacity: 0.45, dur: 10, turb: 0.8, count: 4...7),

        // Intense amber-red — slow shimmer, UV haze feel.
        "heat": makeTheme("heat", angle: 180, bg: "E2DCEC", "F0E0D2", orbs: [
            orb(size: 160, "FA8095", "F86880"),
            orb(size: 100, "FBA078", "FB9268"),
            orb(size:  75, "FFE078", "FCC558"),
        ], blur: 40, opacity: 0.50, dur: 24, turb: 0.1, count: 4...6),

        // Ice-pale, stiff — near-static. Everything feels locked.
        "frost": makeTheme("frost", angle: 145, bg: "EEF3F9", "D8E5F0", orbs: [
            orb(size: 140, "A8CCE8", "82AED2"),
            orb(size:  75, "BFB0E2", "9888CC"),
            orb(size: 105, "C2D5E8", "98B5D2"),
            orb(size:  60, "E5EEF6", "BFD2E2"),
            orb(size:  50, "D8E5F0", "B0C5DC"),
        ], blur: 30, opacity: 0.40, dur: 26, turb: 0.1, count: 4...8),

        // Deep navy — slow drift, dim opacity. Stars implied.
        "clear-night": makeTheme("clear-night", dark: true, angle: 175, bg: "16203F", "445582", orbs: [
            orb(size: 155, "3A4A78", "28365A"),
            orb(size:  80, "B0A0E2", "7866C0"),
            orb(size: 110, "5F6FA0", "3A4878"),
        ], blur: 30, opacity: 0.35, dur: 28, turb: 0.0, count: 3...5),
    ]

    // MARK: - WMO Code → Base Theme

    static func baseTheme(wmoCode: Int, hour: Int) -> WeatherBaseTheme {
        let t = allThemes
        switch wmoCode {
        case 0, 1:
            switch hour {
            case 5:              return t["sunrise"]!       // pre-dawn 어스름한 블루
            case 6...8:          return t["sunrise-warm"]!  // 실제 일출 — 웜 오렌지 글로우
            case 9...16:         return t["clear-day"]!
            case 17...19:        return t["sunrise-warm"]!  // 황금빛 저녁
            case 20:             return t["sunrise"]!       // 해 진 직후 블루-라벤더
            default:             return t["clear-night"]!
            }
        case 2:           return t["partly-cloudy"]!
        case 3:           return t["cloudy"]!
        case 4, 5, 6, 7:  return t["hazy"]!
        case 45, 48:      return t["mist"]!
        case 51, 53, 55:  return t["drizzle"]!
        case 56, 57:      return t["drizzle"]!
        case 61, 63:      return t["rain"]!
        case 65:          return t["rain"]!
        case 66, 67:      return t["rain"]!
        case 71, 73:      return t["snow"]!
        case 75:          return t["blizzard"]!
        case 77:          return t["frost"]!
        case 80, 81, 82:  return t["showers"]!
        case 85, 86:      return t["snow"]!
        case 95:          return t["thunderstorm"]!
        case 96, 99:      return t["thunderstorm"]!
        default:          return t["clear-day"]!
        }
    }

    // MARK: - Time-of-Day Color Temperature Modifier

    // 기존 clear-sky 팔레트 색상을 기준점으로 삼아 시간대별 색온도를 결정.
    // clear-night(네이비) → sunrise(블루-라벤더) → sunrise-warm(웜 오렌지) → clear-day(낮, 기준값)
    // WMO 0,1은 이미 시간별 테마 교체로 처리되므로 이 함수는 나머지 조건에만 적용.
    private static func timeOfDayModifier(hour: Int)
        -> (brightness: Double, saturation: Double, hueShift: Double,
            overlayColor: Color, overlayOpacity: Double) {
        switch hour {
        case 0...4:  return (0.50, 0.60, +18, Color(red: 12/255, green: 18/255, blue: 75/255),  0.52)
        case 5:      return (0.65, 0.72, +12, Color(red: 60/255, green: 72/255, blue: 160/255), 0.30)
        case 6:      return (0.80, 0.88,  -6, Color(red: 240/255, green: 110/255, blue: 60/255), 0.20)
        case 7:      return (0.88, 0.93,  -9, Color(red: 255/255, green: 128/255, blue: 55/255), 0.17)
        case 8:      return (0.93, 0.96,  -6, Color(red: 255/255, green: 148/255, blue: 70/255), 0.10)
        case 9...16: return (1.00, 1.00,   0, .clear, 0.00)
        case 17:     return (0.90, 0.95,  -8, Color(red: 255/255, green: 128/255, blue: 48/255), 0.14)
        case 18:     return (0.84, 0.90, -10, Color(red: 240/255, green: 108/255, blue: 42/255), 0.20)
        case 19:     return (0.78, 0.85,  -7, Color(red: 220/255, green:  95/255, blue: 50/255), 0.18)
        case 20:     return (0.68, 0.75, +10, Color(red:  55/255, green:  65/255, blue: 155/255), 0.25)
        case 21:     return (0.56, 0.64, +16, Color(red:  15/255, green:  20/255, blue:  82/255), 0.45)
        case 22:     return (0.52, 0.61, +18, Color(red:  12/255, green:  18/255, blue:  78/255), 0.50)
        default:     return (0.50, 0.60, +18, Color(red:  12/255, green:  18/255, blue:  75/255), 0.52)
        }
    }

    // MARK: - Temperature → Hue Offset (°)

    static func temperatureHueOffset(_ temperature: Double) -> Double {
        switch temperature {
        case ..<(-5):  return +15
        case -5..<5:   return  +8
        case 5..<15:   return  +3
        case 15..<22:  return   0
        case 22..<28:  return  -5
        case 28..<35:  return -10
        default:       return -15
        }
    }

    // MARK: - Humidity → Blur add + Opacity multiplier

    private static func humidityModifiers(_ h: Double) -> (blurAdd: CGFloat, opacityMul: Double) {
        switch h {
        case 0..<30:  return ( 0, 1.00)
        case 30..<55: return ( 5, 0.95)
        case 55..<75: return (10, 0.90)
        case 75..<90: return (15, 0.85)
        default:      return (20, 0.80)
        }
    }

    // MARK: - Wind Speed → Duration divisor + Displacement

    private static func windModifiers(_ w: Double) -> (durationDiv: Double, displacement: Double) {
        switch w {
        case 0..<1:   return (1.00, 28)
        case 1..<3:   return (1.10, 36)
        case 3..<7:   return (1.20, 46)
        case 7..<14:  return (1.35, 58)
        case 14..<25: return (1.55, 72)
        default:      return (1.80, 88)
        }
    }

    // MARK: - Cloud Cover → Brightness + Saturation

    static func cloudCoverParams(_ c: Double) -> (brightness: Double, saturation: Double) {
        switch c {
        case 0..<15:  return (1.00, 1.00)
        case 15..<35: return (0.97, 0.95)
        case 35..<60: return (0.90, 0.82)
        case 60..<80: return (0.83, 0.68)
        default:      return (0.75, 0.55)
        }
    }

    // MARK: - Seeded Layout

    static func seededLayout(
        palette: [OrbDefinition],
        countRange: ClosedRange<Int>,
        launchSeed: Int
    ) -> (blobs: [BlobParams], angleOffset: Double) {
        var rng = SeededRandom(seed: launchSeed)
        let count = Int.random(in: countRange, using: &rng)

        let blobs: [BlobParams] = (0..<count).map { i in
            let orb = palette[i % palette.count]
            return BlobParams(
                xPercent:       Double.random(in: 0...100, using: &rng),
                yPercent:       Double.random(in: 0...100, using: &rng),
                sizePercent:    orb.sizePercent * Double.random(in: 0.88...1.12, using: &rng),
                startColor:     orb.startColor,
                endColor:       orb.endColor,
                animationDelay: -Double.random(in: 0...12, using: &rng)
            )
        }

        let angleOffset = Double.random(in: -18...18, using: &rng)
        return (blobs, angleOffset)
    }

    // MARK: - Compute All Visual Params

    // themeId를 직접 지정할 때 사용 (Draft 비교 프리뷰 등)
    static func computeParams(
        themeId: String,
        temperature: Double,
        humidity: Double,
        windSpeed: Double,
        cloudCover: Double,
        launchSeed: Int
    ) -> WeatherVisualParams {
        let theme = allThemes[themeId] ?? allThemes["clear-day"]!
        return computeParams(
            theme:       theme,
            temperature: temperature,
            humidity:    humidity,
            windSpeed:   windSpeed,
            cloudCover:  cloudCover,
            launchSeed:  launchSeed
        )
    }

    static func computeParams(
        wmoCode: Int,
        temperature: Double,
        humidity: Double,
        windSpeed: Double,
        cloudCover: Double,
        hour: Int,
        launchSeed: Int
    ) -> WeatherVisualParams {
        let theme = baseTheme(wmoCode: wmoCode, hour: hour)
        let base  = computeParams(
            theme:       theme,
            temperature: temperature,
            humidity:    humidity,
            windSpeed:   windSpeed,
            cloudCover:  cloudCover,
            launchSeed:  launchSeed
        )
        // WMO 0,1은 시간별 테마 교체로 이미 처리됨 — TOD modifier 생략
        guard wmoCode != 0, wmoCode != 1 else { return base }

        let tod = timeOfDayModifier(hour: hour)
        return WeatherVisualParams(
            theme:               base.theme,
            blurRadius:          base.blurRadius,
            orbOpacity:          base.orbOpacity,
            animationDuration:   base.animationDuration,
            displacementPercent: base.displacementPercent,
            brightnessScale:     base.brightnessScale * tod.brightness,
            saturationScale:     base.saturationScale  * tod.saturation,
            hueOffset:           base.hueOffset + tod.hueShift,
            turbulence:          base.turbulence,
            pulseEnabled:        base.pulseEnabled,
            blobs:               base.blobs,
            gradientAngleOffset: base.gradientAngleOffset,
            nightOverlayColor:   tod.overlayColor,
            nightOverlayOpacity: tod.overlayOpacity
        )
    }

    private static func computeParams(
        theme: WeatherBaseTheme,
        temperature: Double,
        humidity: Double,
        windSpeed: Double,
        cloudCover: Double,
        launchSeed: Int
    ) -> WeatherVisualParams {
        let (blurAddRaw, opacityMul)    = humidityModifiers(humidity)
        let (durationDiv, displacement) = windModifiers(windSpeed)
        let (brightness, saturation)    = cloudCoverParams(cloudCover)
        let hue                         = temperatureHueOffset(temperature)
        let (blobs, angle)              = seededLayout(
            palette:    theme.orbs,
            countRange: theme.blobCountRange,
            launchSeed: launchSeed
        )

        // 어두운 테마(thunderstorm, clear-night 등)는 배경색 자체가 이미 흐린 날씨를 표현.
        // cloudCover 채도·밝기 보정과 humidity blur 증가를 중복 적용하면 오브 색이 사라짐.
        let blurAdd:    CGFloat = theme.isDark ? min(blurAddRaw, 6) : blurAddRaw
        let satScale:   Double  = theme.isDark ? max(saturation,  0.90) : saturation
        let brightScale: Double = theme.isDark ? max(brightness,  0.95) : brightness

        return WeatherVisualParams(
            theme:               theme,
            blurRadius:          theme.baseBlurRadius + blurAdd,
            orbOpacity:          theme.baseOrbOpacity * (theme.isDark ? 1.0 : opacityMul),
            animationDuration:   theme.baseAnimDuration / durationDiv,
            displacementPercent: displacement,
            brightnessScale:     brightScale,
            saturationScale:     satScale,
            hueOffset:           hue,
            turbulence:          theme.turbulence,
            pulseEnabled:        theme.pulseEnabled,
            blobs:               blobs,
            gradientAngleOffset: angle,
            nightOverlayColor:   .clear,
            nightOverlayOpacity: 0
        )
    }
}
