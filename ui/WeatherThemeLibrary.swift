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

// MARK: - Orb Palette Entry
// 위치 없음 — 색상과 기본 크기만 정의. 실제 위치는 launchSeed가 결정.

struct OrbDefinition {
    let sizePercent: Double  // 프레임 너비 기준 기본 지름 %
    let startColor: Color    // radial gradient 안쪽
    let endColor: Color      // radial gradient 바깥 (투명으로 페이드)
}

// MARK: - Blob Params (렌더링에 필요한 모든 값, blob 1개 기준)

struct BlobParams {
    let xPercent: Double       // 0–100, 프레임 기준 center X (완전 랜덤)
    let yPercent: Double       // 0–100, 프레임 기준 center Y (완전 랜덤)
    let sizePercent: Double    // 기본 크기 × seed 배수
    let startColor: Color
    let endColor: Color
    let animationDelay: Double // 음수 초, 사이클 선행 오프셋
}

// MARK: - Base Theme

struct WeatherBaseTheme {
    let id: String
    let isDark: Bool
    let backgroundStart: Color
    let backgroundEnd: Color
    let backgroundAngle: Double
    let orbs: [OrbDefinition]  // 색상/크기 팔레트. blob 수가 더 많으면 순환 사용.
}

// MARK: - Visual Parameters (최종 출력)

struct WeatherVisualParams {
    // Layer 1 — WeatherData에서 직접 계산
    let theme: WeatherBaseTheme
    let blurRadius: CGFloat
    let orbOpacity: Double
    let animationDuration: Double    // 애니메이션 한 사이클 (초)
    let displacementPercent: Double  // blob 이동 범위 ±%
    let brightnessScale: Double      // orb HSL L 채널 배수
    let saturationScale: Double      // orb HSL S 채널 배수
    let hueOffset: Double            // 온도 기반 색조 회전 (°)

    // Layer 2 — launchSeed에서 생성
    let blobs: [BlobParams]          // 위치·크기·딜레이 포함, 완전 랜덤 배치
    let gradientAngleOffset: Double  // backgroundAngle에 더해지는 오프셋
}

// MARK: - WeatherThemeLibrary

struct WeatherThemeLibrary {

    // MARK: Shorthand Builders

    // Color(hex:) 대신 직접 파싱 — DesignTokens extension 충돌 방지
    private static func c(_ hex: String) -> Color {
        var n: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&n)
        return Color(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >>  8) & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }

    private static func makeTheme(
        _ id: String, dark: Bool = false, angle: Double,
        bg start: String, _ end: String,
        orbs: [OrbDefinition]
    ) -> WeatherBaseTheme {
        WeatherBaseTheme(
            id: id, isDark: dark,
            backgroundStart: c(start),
            backgroundEnd:   c(end),
            backgroundAngle: angle,
            orbs: orbs
        )
    }

    private static func orb(size: Double, _ start: String, _ end: String) -> OrbDefinition {
        OrbDefinition(sizePercent: size, startColor: c(start), endColor: c(end))
    }

    // MARK: Theme Catalog

    static let allThemes: [String: WeatherBaseTheme] = [

        // ── Atmosphere ───────────────────────────────────────────────────

        "sunrise": makeTheme("sunrise", angle: 180, bg: "F8F1E8", "FCEFE0", orbs: [
            orb(size: 160, "FF9582", "F89383"),
            orb(size: 105, "FFB893", "FA9F7A"),
            orb(size:  65, "FFE2A0", "FFCE78"),
        ]),

        "clear-day": makeTheme("clear-day", angle: 200, bg: "FCF7E8", "F8EFD0", orbs: [
            orb(size: 155, "FFE56A", "F9CF40"),
            orb(size:  95, "FFE49E", "FBCE6E"),
            orb(size:  60, "F8EAB8", "ECD482"),
        ]),

        "partly-cloudy": makeTheme("partly-cloudy", angle: 165, bg: "F2F5F9", "E8EDF4", orbs: [
            orb(size: 145, "BCD2EE", "98B8E0"),
            orb(size:  90, "FFC598", "F5A572"),
            orb(size:  60, "F0E5DC", "DECBB8"),
        ]),

        "cloudy": makeTheme("cloudy", angle: 180, bg: "EDF1F6", "DDE5EE", orbs: [
            orb(size: 150, "C0CFE0", "A2BAD2"),
            orb(size:  95, "CDDAEA", "A8BDD5"),
            orb(size:  80, "D0DCEC", "ADC2D8"),
            orb(size:  55, "E5DDD0", "C8B9A5"),
        ]),

        "overcast": makeTheme("overcast", angle: 195, bg: "F1E8E8", "E2D2D5", orbs: [
            orb(size: 145, "E4B0B8", "C68C9A"),
            orb(size:  90, "E0B8C0", "C292A0"),
            orb(size:  60, "F0E0DC", "DAC2BA"),
        ]),

        // ── Precipitation ────────────────────────────────────────────────

        "rain": makeTheme("rain", dark: true, angle: 175, bg: "4A82CC", "EEF3F8", orbs: [
            orb(size: 165, "6B95DD", "4A78C8"),
            orb(size: 110, "8B9DE8", "6F7BD3"),
            orb(size:  70, "E5ECF6", "C8D8EC"),
        ]),

        "drizzle": makeTheme("drizzle", angle: 210, bg: "F0F4F8", "E2EAF2", orbs: [
            orb(size: 150, "B0C8E2", "88A8CC"),
            orb(size:  70, "C2BCE2", "9F98CC"),
        ]),

        "thunderstorm": makeTheme("thunderstorm", dark: true, angle: 155, bg: "3D335E", "D8A07A", orbs: [
            orb(size: 155, "6B4FB0", "4A2F88"),
            orb(size: 115, "B582CC", "8E5DAE"),
            orb(size:  95, "FFC596", "ECA876"),
            orb(size:  60, "7A5CB0", "5A4290"),
        ]),

        "snow": makeTheme("snow", angle: 180, bg: "F4F8FB", "E5EEF4", orbs: [
            orb(size: 150, "FAFCFE", "DEE9F2"),
            orb(size:  75, "C8D8E8", "A2B8D0"),
            orb(size:  60, "E5EEF6", "BFD2E2"),
            orb(size:  90, "FAFCFE", "D8E5F0"),
            orb(size:  50, "D5E2EC", "B0C5DA"),
        ]),

        "blizzard": makeTheme("blizzard", angle: 190, bg: "DCE6F2", "B5C8DE", orbs: [
            orb(size: 160, "C2D5EC", "94B0D2"),
            orb(size:  90, "DCE6F2", "B2C5DC"),
            orb(size:  65, "C8D2E2", "A2B0C8"),
        ]),

        // ── Visibility ───────────────────────────────────────────────────

        "showers": makeTheme("showers", angle: 135, bg: "F0F5F8", "D8E5EE", orbs: [
            orb(size: 145, "92BFDB", "6FA5D2"),
            orb(size: 115, "A2D2C5", "80BCAE"),
            orb(size:  70, "A2C2D5", "7FA9C5"),
        ]),

        "mist": makeTheme("mist", angle: 200, bg: "F5F2F8", "EAE5F0", orbs: [
            orb(size: 155, "F0BCD2", "DA9CBC"),
            orb(size: 110, "BFB2E0", "9C90CE"),
            orb(size:  70, "F0E5D8", "DACFC0"),
        ]),

        "smoke": makeTheme("smoke", angle: 220, bg: "F8F0E2", "EDDFC8", orbs: [
            orb(size: 150, "F0D4A8", "D2B58A"),
            orb(size: 100, "F5E8D0", "DCC8A2"),
            orb(size:  60, "EAC8C2", "D2A4A0"),
        ]),

        "dust": makeTheme("dust", dark: true, angle: 160, bg: "D2BC95", "B59872", orbs: [
            orb(size: 145, "E8C58E", "C8A565"),
            orb(size: 100, "D5AC78", "B08856"),
            orb(size:  95, "DEB46E", "BE9050"),
            orb(size:  60, "A88752", "8E6D38"),
        ]),

        "windy": makeTheme("windy", angle: 45, bg: "F0F5F2", "DCE8E0", orbs: [
            orb(size: 155, "BCDDC8", "9CCEB5"),
            orb(size: 115, "EDE48E", "DCCF6E"),
            orb(size:  85, "B5D2D8", "88B2BC"),
        ]),

        // ── Special ──────────────────────────────────────────────────────

        "sandstorm": makeTheme("sandstorm", dark: true, angle: 0, bg: "C2A57E", "9E7E50", orbs: [
            orb(size: 155, "E8C586", "C8A065"),
            orb(size:  95, "C8986F", "A0764C"),
            orb(size: 115, "8E6442", "6E4A28"),
        ]),

        "heat": makeTheme("heat", angle: 180, bg: "E2DCEC", "F0E0D2", orbs: [
            orb(size: 160, "FA8095", "F86880"),
            orb(size: 100, "FBA078", "FB9268"),
            orb(size:  75, "FFE078", "FCC558"),
        ]),

        "frost": makeTheme("frost", angle: 145, bg: "EEF3F9", "D8E5F0", orbs: [
            orb(size: 140, "A8CCE8", "82AED2"),
            orb(size:  75, "BFB0E2", "9888CC"),
            orb(size: 105, "C2D5E8", "98B5D2"),
            orb(size:  60, "E5EEF6", "BFD2E2"),
            orb(size:  50, "D8E5F0", "B0C5DC"),
        ]),

        "clear-night": makeTheme("clear-night", dark: true, angle: 175, bg: "16203F", "445582", orbs: [
            orb(size: 155, "3A4A78", "28365A"),
            orb(size:  80, "B0A0E2", "7866C0"),
            orb(size: 110, "5F6FA0", "3A4878"),
        ]),

        "hazy": makeTheme("hazy", angle: 215, bg: "FCF3E5", "F5DEBD", orbs: [
            orb(size: 150, "FFCC92", "F6AC68"),
            orb(size: 105, "FCB8AC", "EF9080"),
            orb(size:  70, "FFDDA8", "F8C078"),
        ]),
    ]

    // MARK: - WMO Code → Base Theme

    static func baseTheme(wmoCode: Int, hour: Int) -> WeatherBaseTheme {
        let t = allThemes
        switch wmoCode {
        case 0:
            switch hour {
            case 5...7, 17...19: return t["sunrise"]!
            case 8...16:         return t["clear-day"]!
            default:             return t["clear-night"]!
            }
        case 1:           return t["clear-day"]!
        case 2:           return t["partly-cloudy"]!
        case 3:           return t["overcast"]!
        case 45, 48:      return t["mist"]!
        case 51, 53, 55:  return t["drizzle"]!
        case 56, 57:      return t["drizzle"]!
        case 61, 63, 65:  return t["rain"]!
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

    // MARK: - WMO Code → Blob Count Range

    static func blobCountRange(wmoCode: Int) -> ClosedRange<Int> {
        switch wmoCode {
        case 0, 1:            return 2...6
        case 2:               return 2...7
        case 3:               return 3...8
        case 45, 48:          return 4...10
        case 51, 53, 55:      return 2...5
        case 56, 57:          return 3...7
        case 61, 63, 65,
             66, 67,
             80, 81, 82:      return 3...9
        case 71, 73, 75,
             77, 85, 86:      return 4...12
        case 95:              return 2...5
        case 96, 99:          return 3...6
        default:              return 2...6
        }
    }

    // MARK: - Temperature → Hue Offset (°)
    // 차가울수록 +방향(파랑), 더울수록 -방향(빨강/오렌지)

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

    // MARK: - Humidity → Blur + Opacity

    static func humidityParams(_ humidity: Double) -> (blurRadius: CGFloat, opacity: Double) {
        switch humidity {
        case 0..<20:  return ( 6, 0.70)
        case 20..<40: return (10, 0.76)
        case 40..<60: return (16, 0.82)
        case 60..<75: return (22, 0.88)
        case 75..<90: return (28, 0.93)
        default:      return (35, 0.97)
        }
    }

    // MARK: - Wind Speed → Animation Duration + Displacement

    static func windParams(_ windSpeed: Double) -> (duration: Double, displacement: Double) {
        switch windSpeed {
        case 0..<1:   return (12, 28)
        case 1..<3:   return (10, 36)
        case 3..<7:   return ( 8, 46)
        case 7..<14:  return ( 6, 56)
        case 14..<25: return ( 4, 68)
        default:      return ( 3, 80)
        }
    }

    // MARK: - Cloud Cover → Brightness + Saturation

    static func cloudCoverParams(_ cloudCover: Double) -> (brightness: Double, saturation: Double) {
        switch cloudCover {
        case 0..<15:  return (1.00, 1.00)
        case 15..<35: return (0.97, 0.95)
        case 35..<60: return (0.90, 0.82)
        case 60..<80: return (0.83, 0.68)
        default:      return (0.75, 0.55)
        }
    }

    // MARK: - Launch Seed → Blob Layout (완전 자유 배치)
    // - blob 개수: wmoCode 범위 안에서 seed로 결정
    // - 위치: 화면 전체(0~100%) 완전 랜덤
    // - 팔레트 초과 시 색상 순환 사용

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
                xPercent:      Double.random(in: 0...100, using: &rng),
                yPercent:      Double.random(in: 0...100, using: &rng),
                sizePercent:   orb.sizePercent * Double.random(in: 0.88...1.12, using: &rng),
                startColor:    orb.startColor,
                endColor:      orb.endColor,
                animationDelay: -Double.random(in: 0...12, using: &rng)
            )
        }

        let angleOffset = Double.random(in: -18...18, using: &rng)
        return (blobs, angleOffset)
    }

    // MARK: - Compute All Visual Params

    static func computeParams(
        wmoCode: Int,
        temperature: Double,
        humidity: Double,
        windSpeed: Double,
        cloudCover: Double,
        hour: Int,
        launchSeed: Int
    ) -> WeatherVisualParams {
        let theme                    = baseTheme(wmoCode: wmoCode, hour: hour)
        let (blur, opacity)          = humidityParams(humidity)
        let (duration, displacement) = windParams(windSpeed)
        let (brightness, saturation) = cloudCoverParams(cloudCover)
        let hue                      = temperatureHueOffset(temperature)
        let countRange               = blobCountRange(wmoCode: wmoCode)
        let (blobs, angle)           = seededLayout(palette: theme.orbs, countRange: countRange, launchSeed: launchSeed)

        return WeatherVisualParams(
            theme:               theme,
            blurRadius:          blur,
            orbOpacity:          opacity,
            animationDuration:   duration,
            displacementPercent: displacement,
            brightnessScale:     brightness,
            saturationScale:     saturation,
            hueOffset:           hue,
            blobs:               blobs,
            gradientAngleOffset: angle
        )
    }
}
