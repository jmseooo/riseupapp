import SwiftUI

// 배경 모션·색상 실험용 — Draft_HomeView 전용
// HomeView의 WeatherThemeBackground에는 영향 없음

// MARK: - Hex helper

private func dc(_ hex: String) -> Color {
    var n: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&n)
    return Color(
        red:   Double((n >> 16) & 0xFF) / 255,
        green: Double((n >>  8) & 0xFF) / 255,
        blue:  Double( n        & 0xFF) / 255
    )
}

// MARK: - 항상 노출되는 웜 옐로우 액센트 (모든 테마에서 yellow base 유지)

private let warmYellow = (start: dc("FFE059"), end: dc("FFC026"))

// MARK: - 테마별 포인트 컬러

private let pointColors: [String: (Color, Color)] = [
    "sunrise":       (dc("F0C8C0"), dc("D8A8A0")),
    "clear-day":     (dc("F0D0B8"), dc("D8B098")),
    "partly-cloudy": (dc("F0D8C8"), dc("D8B8A8")),
    "cloudy":        (dc("E8D0C0"), dc("D0B0A0")),
    "overcast":      (dc("E0C8C0"), dc("C8A8A0")),
    "rain":          (dc("D0C8E0"), dc("B0A8C8")),
    "showers":       (dc("C8C0D8"), dc("A8A0C0")),
    "drizzle":       (dc("D0C8D8"), dc("B0A8C0")),
    "snow":          (dc("F0D8E0"), dc("D8B8C8")),
    "blizzard":      (dc("E8D0D8"), dc("D0B0C0")),
    "frost":         (dc("E0D0D8"), dc("C8B0C0")),
    "clear-night":   (dc("C8A0B0"), dc("A88090")),
    "thunderstorm":  (dc("F0E8A0"), dc("D8D080")),
    "hazy":          (dc("F0D8B8"), dc("D8B898")),
    "mist":          (dc("E8D8C8"), dc("D0B8A8")),
    "dust":          (dc("E8D0B0"), dc("D0B090")),
    "sandstorm":     (dc("E0C8A8"), dc("C8A888")),
    "windy":         (dc("C8E8D8"), dc("A8D0B8")),
    "heat":          (dc("F0A898"), dc("D88878")),
]

// MARK: - Draft_WeatherThemeBackground

struct Draft_WeatherThemeBackground: View {
    let weather: WeatherData?
    let hour: Int

    @State private var launchSeed = UUID().hashValue

    private var themeId: String {
        let wmo = weather?.weatherCode ?? 0
        return WeatherThemeLibrary.baseTheme(wmoCode: wmo, hour: hour).id
    }

    private var visualParams: WeatherVisualParams {
        WeatherThemeLibrary.computeParams(
            wmoCode:     weather?.weatherCode  ?? 0,
            temperature: weather?.temperature  ?? 18,
            humidity:    Double(weather?.humidity   ?? 50),
            windSpeed:   (weather?.windSpeed   ?? 10) / 3.6,
            cloudCover:  Double(weather?.cloudCover ?? 20),
            hour:        hour,
            launchSeed:  launchSeed
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if #available(iOS 18.0, *) {
                    DraftMeshBackground(themeId: themeId, size: geo.size, params: visualParams)
                } else {
                    DraftBlobBackground(weather: weather, hour: hour,
                                        launchSeed: launchSeed, size: geo.size)
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Orb Background (iOS 18+)
// 블러 처리된 원형 오브 3개가 배경 위에서 독립적으로 움직임

@available(iOS 18.0, *)
private struct DraftMeshBackground: View {
    let themeId: String
    let size:    CGSize
    let params:  WeatherVisualParams

    @State private var ox1 = false   // orb1 X
    @State private var oy1 = false   // orb1 Y
    @State private var ox2 = false   // orb2 X
    @State private var oy2 = false   // orb2 Y
    @State private var ox3 = false   // orb3 X
    @State private var oy3 = false   // orb3 Y

    private var palette: DraftPalette { DraftPalette.palette(for: themeId) }
    private var spd: Double { max(0.55, min(1.6, params.animationDuration / 10.0)) }
    private var orbBlur: CGFloat { CGFloat(60 + params.blurRadius * 0.6) }
    private var orbD: CGFloat { size.width * 1.15 }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            // Orb 1 — 기본 크기, 상단 중심 이동
            Circle()
                .fill(palette.orb1)
                .frame(width: orbD, height: orbD)
                .blur(radius: orbBlur)
                .offset(
                    x: ox1 ?  size.width * 0.32 : -size.width * 0.28,
                    y: oy1 ? -size.height * 0.22 :  size.height * 0.12
                )

            // Orb 2 — 약간 크게, 중단 이동
            Circle()
                .fill(palette.orb2)
                .frame(width: orbD * 1.1, height: orbD * 1.1)
                .blur(radius: orbBlur * 1.05)
                .offset(
                    x: ox2 ? -size.width * 0.20 :  size.width * 0.25,
                    y: oy2 ?  size.height * 0.26 : -size.height * 0.08
                )

            // Orb 3 — 약간 작게, 하단 이동
            Circle()
                .fill(palette.orb3)
                .frame(width: orbD * 0.85, height: orbD * 0.85)
                .blur(radius: orbBlur * 0.9)
                .offset(
                    x: ox3 ?  size.width * 0.12 : -size.width * 0.22,
                    y: oy3 ?  size.height * 0.32 : -size.height * 0.18
                )
        }
        .saturation(params.saturationScale)
        .brightness(params.brightnessScale - 1.0)
        .hueRotation(.degrees(params.hueOffset * 0.25))
        .ignoresSafeArea()
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        let s = spd
        withAnimation(.easeInOut(duration:  5.0 * s).repeatForever(autoreverses: true))              { ox1 = true }
        withAnimation(.easeInOut(duration:  7.0 * s).repeatForever(autoreverses: true).delay(0.5))   { oy1 = true }
        withAnimation(.easeInOut(duration:  8.5 * s).repeatForever(autoreverses: true).delay(0.8))   { ox2 = true }
        withAnimation(.easeInOut(duration:  6.0 * s).repeatForever(autoreverses: true).delay(1.3))   { oy2 = true }
        withAnimation(.easeInOut(duration:  6.5 * s).repeatForever(autoreverses: true).delay(1.6))   { ox3 = true }
        withAnimation(.easeInOut(duration:  4.5 * s).repeatForever(autoreverses: true).delay(0.3))   { oy3 = true }
    }
}

// MARK: - Blob Fallback (iOS 17)

private struct DraftBlobBackground: View {
    let weather:    WeatherData?
    let hour:       Int
    let launchSeed: Int
    let size:       CGSize

    private var params: WeatherVisualParams {
        let wmo   = weather?.weatherCode  ?? 0
        let temp  = weather?.temperature  ?? 18.0
        let humid = Double(weather?.humidity  ?? 50)
        let wind  = (weather?.windSpeed   ?? 10.0) / 3.6
        let cloud = Double(weather?.cloudCover ?? 20)
        return WeatherThemeLibrary.computeParams(
            wmoCode: wmo, temperature: temp, humidity: humid,
            windSpeed: wind, cloudCover: cloud, hour: hour, launchSeed: launchSeed
        )
    }

    var body: some View {
        ZStack {
            let rad = (params.theme.backgroundAngle + params.gradientAngleOffset) * .pi / 180
            LinearGradient(
                colors: [params.theme.backgroundStart, params.theme.backgroundEnd],
                startPoint: UnitPoint(x: 0.5 - sin(rad) / 2, y: 0.5 - cos(rad) / 2),
                endPoint:   UnitPoint(x: 0.5 + sin(rad) / 2, y: 0.5 + cos(rad) / 2)
            )
            .ignoresSafeArea()

            ForEach(0..<params.blobs.count, id: \.self) { i in
                DraftOrb(blob: params.blobs[i], params: params,
                         size: size, index: i, blobCount: params.blobs.count)
            }
        }
    }
}

// MARK: - DraftOrb (3-layer 유기적 움직임)

private struct DraftOrb: View {
    let blob:      BlobParams
    let params:    WeatherVisualParams
    let size:      CGSize
    let index:     Int
    let blobCount: Int

    @State private var p1 = false
    @State private var p2 = false
    @State private var p3 = false
    @State private var breathIn   = false
    @State private var aspectFlip = false

    private var cx: CGFloat { blob.xPercent / 100 * size.width  }
    private var cy: CGFloat { blob.yPercent / 100 * size.height }
    private var baseBlobSize: CGFloat { max(blob.sizePercent / 100 * max(size.width, size.height) * 2.2, 1) }
    private var breathScale:  CGFloat { breathIn   ? 1.12 : 0.90 }
    private var aspectFactor: CGFloat { aspectFlip ? 1.25 : 0.80 }

    private var dispScale: CGFloat { CGFloat(params.displacementPercent / 80.0) }
    private var a1x: CGFloat { size.width  * 0.130 * dispScale }
    private var a1y: CGFloat { size.height * 0.100 * dispScale }
    private var a2x: CGFloat { size.width  * 0.070 * dispScale }
    private var a2y: CGFloat { size.height * 0.054 * dispScale }
    private var a3x: CGFloat { size.width  * 0.038 * dispScale }
    private var a3y: CGFloat { size.height * 0.028 * dispScale }

    private var baseT: Double { params.animationDuration * (1.6 + Double(index % 5) * 0.38) }
    private var dur1:  Double { baseT }
    private var dur2:  Double { baseT * 1.618 }
    private var dur3:  Double { baseT * 0.5774 }

    private var xs1: CGFloat { (index     % 2 == 0) ?  1 : -1 }
    private var ys1: CGFloat { (index     % 3 == 0) ?  1 : -1 }
    private var xs2: CGFloat { (index / 2 % 2 == 0) ? -1 :  1 }
    private var ys2: CGFloat { (index / 2 % 3 == 0) ? -1 :  1 }
    private var xs3: CGFloat { (index / 3 % 2 == 0) ?  1 : -1 }
    private var ys3: CGFloat { (index / 3 % 3 == 0) ? -1 :  1 }

    private var isWarmAccent: Bool { index == blobCount - 1 }
    private var orbColors: (Color, Color) {
        if isWarmAccent { return (warmYellow.start, warmYellow.end) }
        if index % 4 == 2, let pt = pointColors[params.theme.id] { return pt }
        return (blob.endColor, blob.startColor)
    }
    private var effectiveOpacity: Double {
        isWarmAccent && params.theme.isDark ? params.orbOpacity * 0.55 : params.orbOpacity
    }

    var body: some View {
        let (cs, ce) = orbColors
        Ellipse()
            .fill(RadialGradient(
                colors: [cs.opacity(effectiveOpacity), ce.opacity(effectiveOpacity * 0.18), .clear],
                center: .center, startRadius: 0, endRadius: baseBlobSize / 2
            ))
            .frame(width:  baseBlobSize * breathScale * aspectFactor,
                   height: baseBlobSize * breathScale / aspectFactor)
            .blur(radius: params.blurRadius * 0.55)
            .saturation(params.saturationScale * 1.8)
            .brightness(params.brightnessScale - 1.0)
            .hueRotation(.degrees(params.hueOffset))
            .position(x: cx, y: cy)
            .offset(x: (p1 ? xs1 : -xs1) * a1x, y: (p1 ? ys1 : -ys1) * a1y)
            .offset(x: (p2 ? xs2 : -xs2) * a2x, y: (p2 ? ys2 : -ys2) * a2y)
            .offset(x: (p3 ? xs3 : -xs3) * a3x, y: (p3 ? ys3 : -ys3) * a3y)
            .onAppear {
                let d1 = Double(index % 5) * 0.35
                let d2 = Double(index % 7) * 0.28
                let d3 = Double(index % 3) * 0.52
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(d1))
                    withAnimation(.easeInOut(duration: dur1).repeatForever(autoreverses: true)) { p1 = true }
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(d2))
                    withAnimation(.easeInOut(duration: dur2).repeatForever(autoreverses: true)) { p2 = true }
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(d3))
                    withAnimation(.easeInOut(duration: dur3).repeatForever(autoreverses: true)) { p3 = true }
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Double(index % 4) * 0.6))
                    withAnimation(.easeInOut(duration: 4.5 + Double(index % 5) * 0.8)
                        .repeatForever(autoreverses: true)) { breathIn = true }
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Double(index % 3) * 0.9))
                    withAnimation(.easeInOut(duration: 3.8 + Double(index % 7) * 0.6)
                        .repeatForever(autoreverses: true)) { aspectFlip = true }
                }
            }
    }
}

// MARK: - Draft Palette (20가지 날씨 × background + 3 orb 구조)
//
// background: 베이스 솔리드 컬러
// orb1/2/3:  블러 처리된 원형 블롭 3개 (크기: 1.0 / 1.1 / 0.85)
// Frame 919.png 레퍼런스 스워치 직접 반영

private struct DraftPalette {
    let background: Color
    let orb1: Color
    let orb2: Color
    let orb3: Color

    private static func mk(_ bg: String, _ o1: String, _ o2: String, _ o3: String) -> DraftPalette {
        DraftPalette(background: dc(bg), orb1: dc(o1), orb2: dc(o2), orb3: dc(o3))
    }

    static func palette(for themeId: String) -> DraftPalette {
        switch themeId {
        // ── 웜톤 ────────────────────────────────────────────────
        case "sunrise":       return mk("FEF0C0", "F8AA50", "F06840", "F8C880")
        case "clear-day":     return mk("FFF8E0", "FCE488", "F8D474", "F8C498")
        case "hazy":          return mk("FEF0DC", "FBD8B4", "F8C894", "FCE4CC")
        case "smoke":         return mk("E2D6C4", "C4B49C", "B4A28C", "D6C8B4")
        case "heat":          return mk("FEE4A0", "FC9050", "F86044", "E84030")

        // ── 쿨/그레이 ────────────────────────────────────────────
        case "partly-cloudy": return mk("EEF3FA", "CCDAEE", "B8CBDF", "DDE9F5")
        case "cloudy":        return mk("E4EDF6", "BECEDE", "AABECE", "CDDAEB")
        case "overcast":      return mk("F0EEEC", "DCDCD6", "CACAD0", "E8E6E4")
        case "mist":          return mk("F4F4F4", "E0E0E0", "D0D0D4", "ECECEC")

        // ── 블루-아이스 ──────────────────────────────────────────
        case "rain":          return mk("CCDFF0", "7EAACF", "5688C0", "8EB2D8")
        case "drizzle":       return mk("ECF3FC", "C4D8F0", "ACCCEA", "DAECFA")
        case "snow":          return mk("F2F8FC", "D4E8F8", "BCD8F4", "E4F4FC")
        case "blizzard":      return mk("E6EEF6", "BECEDD", "AABECE", "D4E0EE")
        case "frost":         return mk("EEF6FC", "C6E0F4", "AECCEA", "E0F0FA")
        case "dust":          return mk("E8EEF6", "B8CCDE", "A0BCCC", "D0DCEA")

        // ── 특수 ─────────────────────────────────────────────────
        case "windy":         return mk("ECF8F4", "BCDACC", "A4CCBC", "D4EEE8")
        case "showers":       return mk("EEF8F4", "BCE6D8", "9ED4C4", "DAEFE8")
        case "sandstorm":     return mk("8C8070", "504840", "6A6050", "A09080")

        // ── 다크 ─────────────────────────────────────────────────
        case "thunderstorm":  return mk("24243E", "4858A8", "363660", "1C1C38")
        case "clear-night":   return mk("1C2450", "262E6C", "C8A020", "2E3878")

        default:              return mk("FFF8E0", "FCE488", "F8D474", "F8C498")
        }
    }
}

// MARK: - Time Text with Aurora Glow
// ref1: Der Augenblick Pinterest image — 텍스트 뒤 오로라 컬러 블롭
// ref2: 오브 배경 영상 — 블러된 컬러가 UI에 투영되는 글로우

private struct DraftTimeText: View {
    var dark: Bool = false

    @State private var wobbleY: CGFloat = 0

    var body: some View {
        Text("00:00")
            .font(.radioCanadaBig(110))
            .foregroundStyle(dark ? Color.white : Color.rBlackWarm)
            .opacity(0.65)
            .blendMode(.overlay)
            .offset(y: wobbleY)
            .onAppear {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    wobbleY = 3.5
                }
            }
    }
}

// MARK: - Preview (10가지 날씨 조건)

#Preview("① 새벽 맑음") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 16, weatherCode: 0, windSpeed: 5, humidity: 40, cloudCover: 5),
            hour: 6
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("② 맑은 낮") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 26, weatherCode: 0, windSpeed: 10, humidity: 30, cloudCover: 5),
            hour: 13
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("③ 구름 조금") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 22, weatherCode: 2, windSpeed: 12, humidity: 45, cloudCover: 35),
            hour: 12
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("④ 흐림") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 18, weatherCode: 3, windSpeed: 10, humidity: 65, cloudCover: 80),
            hour: 14
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("⑤ 안개") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 14, weatherCode: 45, windSpeed: 3, humidity: 95, cloudCover: 90),
            hour: 9
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("⑥ 이슬비") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 15, weatherCode: 53, windSpeed: 8, humidity: 80, cloudCover: 85),
            hour: 11
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("⑦ 비") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 16, weatherCode: 63, windSpeed: 22, humidity: 88, cloudCover: 90),
            hour: 15
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("⑧ 천둥번개") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 18, weatherCode: 95, windSpeed: 42, humidity: 92, cloudCover: 95),
            hour: 16
        )
        DraftTimeText(dark: true)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("⑨ 눈") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: -2, weatherCode: 73, windSpeed: 10, humidity: 75, cloudCover: 88),
            hour: 10
        )
        DraftTimeText(dark: false)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
#Preview("⑩ 맑은 밤") {
    ZStack(alignment: .bottomLeading) {
        Draft_WeatherThemeBackground(
            weather: WeatherData(temperature: 12, weatherCode: 0, windSpeed: 4, humidity: 55, cloudCover: 5),
            hour: 23
        )
        DraftTimeText(dark: true)
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
    }
}
