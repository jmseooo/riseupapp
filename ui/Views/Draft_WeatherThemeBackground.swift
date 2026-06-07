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

// MARK: - Mesh Background (iOS 18+)

@available(iOS 18.0, *)
private struct DraftMeshBackground: View {
    let themeId: String
    let size:    CGSize
    let params:  WeatherVisualParams

    @State private var q1 = false
    @State private var q2 = false
    @State private var q3 = false
    @State private var r1 = false
    @State private var r2 = false
    @State private var e1 = false
    @State private var colorPhase = false

    private var palette: DraftPalette { DraftPalette.palette(for: themeId) }

    // 바람 세기 → 애니메이션 속도 (animationDuration 크면 느림)
    private var spd: Double { max(0.55, min(1.6, params.animationDuration / 10.0)) }
    // 습도 → 블러 (더 습할수록 약간 더 뭉개짐)
    private var meshBlur: CGFloat { CGFloat(36 + params.blurRadius * 0.4) }

    private var meshPoints: [SIMD2<Float>] {
        let cx1: Float = q1 ? 0.78 : 0.22
        let cx2: Float = q2 ? 0.18 : 0.82
        let cx3: Float = q3 ? 0.72 : 0.28
        let dy1: Float = r1 ?  0.16 : -0.16
        let dy2: Float = r2 ? -0.18 :  0.18
        let ey:  Float = e1 ?  0.10 : -0.10
        return [
            [0.0, 0.00],         [0.50, 0.00],         [1.0, 0.00],
            [0.0, 0.25 + ey],    [cx1,  0.25 + dy1],   [1.0, 0.25 - ey],
            [0.0, 0.50 - ey],    [cx2,  0.50 + dy2],   [1.0, 0.50 + ey],
            [0.0, 0.75 + ey],    [cx3,  0.75 + dy1],   [1.0, 0.75 - ey],
            [0.0, 1.00],         [0.50, 1.00],          [1.0, 1.00],
        ]
    }

    var body: some View {
        MeshGradient(
            width: 3, height: 5,
            points: meshPoints,
            colors: colorPhase ? palette.meshColorsB : palette.meshColorsA,
            smoothsColors: true
        )
        .scaleEffect(1.3)
        .blur(radius: meshBlur)                             // 습도 반영
        .saturation(params.saturationScale)                 // 흐림·비 → 채도 낮춤
        .brightness(params.brightnessScale - 1.0)           // 구름량 → 밝기 조절
        .hueRotation(.degrees(params.hueOffset * 0.25))     // 기온 → 미세 색조 이동
        .ignoresSafeArea()
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        let s = spd   // 바람 세기에 따른 속도 배율
        withAnimation(.easeInOut(duration:  5.0 * s).repeatForever(autoreverses: true))              { q1 = true }
        withAnimation(.easeInOut(duration:  8.5 * s).repeatForever(autoreverses: true).delay(0.8))   { q2 = true }
        withAnimation(.easeInOut(duration:  6.5 * s).repeatForever(autoreverses: true).delay(1.6))   { q3 = true }
        withAnimation(.easeInOut(duration:  4.0 * s).repeatForever(autoreverses: true).delay(0.4))   { r1 = true }
        withAnimation(.easeInOut(duration:  6.0 * s).repeatForever(autoreverses: true).delay(1.2))   { r2 = true }
        withAnimation(.easeInOut(duration:  7.0 * s).repeatForever(autoreverses: true).delay(0.2))   { e1 = true }
        withAnimation(.easeInOut(duration:  9.0 * s).repeatForever(autoreverses: true).delay(2.0))   { colorPhase = true }
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

// MARK: - Draft Palette (20가지 날씨 × 3블롭 삼각 배치)
//
// Frame 919.png 레퍼런스 스워치 색상 직접 반영
// themeId → 스워치 매핑:
//   sunrise/clear-day/hazy/heat          → 웜톤
//   partly-cloudy/cloudy/overcast/mist   → 그레이-쿨
//   drizzle/rain/snow/blizzard/frost     → 블루-아이스
//   thunderstorm/clear-night             → 다크 네이비
//   smoke/windy/sandstorm/showers/dust   → 특수

private struct DraftPalette {
    let meshColorsA: [Color]
    let meshColorsB: [Color]

    // A:b1(상단우)/b2(중심)/b3(하단좌)  →  B:b2(상단우)/b3(중심)/b1(하단좌) — 시계방향 회전
    private static func tri(_ bg: Color, _ b1: Color, _ b2: Color, _ b3: Color) -> DraftPalette {
        DraftPalette(
            meshColorsA: [
                bg, b1, b1,
                bg, b1, b2,
                b2, b2, bg,
                b3, b3, bg,
                b3, bg, bg,
            ],
            meshColorsB: [
                bg, b2, b2,
                bg, b2, b3,
                b3, b3, bg,
                b1, b1, bg,
                b1, bg, bg,
            ]
        )
    }

    static func palette(for themeId: String) -> DraftPalette {
        switch themeId {

        // 1. Sunrise — 골든오렌지+살몬 웜 그라디언트
        case "sunrise":
            return tri(dc("FEF0C0"), dc("F8AA50"), dc("F06840"), dc("F8C880"))

        // 2. Clear Day — 버터옐로우+소프트골드 파스텔
        case "clear-day":
            return tri(dc("FFF8E0"), dc("FCE488"), dc("F8D474"), dc("F8C498"))

        // 3. Partly Cloudy — 라이트 블루-그레이 (매우 연함)
        case "partly-cloudy":
            return tri(dc("EEF3FA"), dc("CCDAEE"), dc("B8CBDF"), dc("DDE9F5"))

        // 4. Cloudy — 블루-그레이 (파틀리보다 채도 조금 높음)
        case "cloudy":
            return tri(dc("E4EDF6"), dc("BECEDE"), dc("AABECE"), dc("CDDAEB"))

        // 5. Overcast — 거의 흰색, 워밍 그레이
        case "overcast":
            return tri(dc("F0EEEC"), dc("DCDCD6"), dc("CACAD0"), dc("E8E6E4"))

        // 6. Rain — 뚜렷한 미드블루
        case "rain":
            return tri(dc("CCDFF0"), dc("7EAACF"), dc("5688C0"), dc("8EB2D8"))

        // 7. Drizzle — 라이트블루 (레인보다 훨씬 연함)
        case "drizzle":
            return tri(dc("ECF3FC"), dc("C4D8F0"), dc("ACCCEA"), dc("DAECFA"))

        // 8. Thunderstorm — 딥 인디고-퍼플네이비
        case "thunderstorm":
            return tri(dc("24243E"), dc("36366C"), dc("3C3468"), dc("1C1C38"))

        // 9. Snow — 아이스 화이트-블루
        case "snow":
            return tri(dc("F2F8FC"), dc("D4E8F8"), dc("BCD8F4"), dc("E4F4FC"))

        // 10. Blizzard — 쿨 그레이-블루 (스노우보다 더 진함)
        case "blizzard":
            return tri(dc("E6EEF6"), dc("BECEDD"), dc("AABECE"), dc("D4E0EE"))

        // 11. Hail(dust) — 라이트 쿨 블루-그레이
        case "dust":
            return tri(dc("E8EEF6"), dc("B8CCDE"), dc("A0BCCC"), dc("D0DCEA"))

        // 12. Fog(mist) — 뉴트럴 거의 화이트
        case "mist":
            return tri(dc("F4F4F4"), dc("E0E0E0"), dc("D0D0D4"), dc("ECECEC"))

        // 13. Haze — 웜 피치-크림 글로우
        case "hazy":
            return tri(dc("FEF0DC"), dc("FBD8B4"), dc("F8C894"), dc("FCE4CC"))

        // 14. Smoke — 웜 탄-카키
        case "smoke":
            return tri(dc("E2D6C4"), dc("C4B49C"), dc("B4A28C"), dc("D6C8B4"))

        // 15. Windy — 라이트 세이지-민트
        case "windy":
            return tri(dc("ECF8F4"), dc("BCDACC"), dc("A4CCBC"), dc("D4EEE8"))

        // 16. Tornado Watch(sandstorm) — 다크 올리브-그레이
        case "sandstorm":
            return tri(dc("766E66"), dc("5A5448"), dc("4E4840"), dc("847C74"))

        // 17. Heatwave — 브라이트 오렌지→레드 그라디언트
        case "heat":
            return DraftPalette(
                meshColorsA: [
                    dc("FEE4A0"), dc("FC9050"), dc("FC9050"),
                    dc("FEE4A0"), dc("FC9050"), dc("F86044"),
                    dc("F86044"), dc("F86044"), dc("FEE4A0"),
                    dc("E84030"), dc("E84030"), dc("FEE4A0"),
                    dc("E84030"), dc("FEE4A0"), dc("FEE4A0"),
                ],
                meshColorsB: [
                    dc("FEE4A0"), dc("F86044"), dc("F86044"),
                    dc("FEE4A0"), dc("F86044"), dc("E84030"),
                    dc("E84030"), dc("E84030"), dc("FEE4A0"),
                    dc("FC9050"), dc("FC9050"), dc("FEE4A0"),
                    dc("FC9050"), dc("FEE4A0"), dc("FEE4A0"),
                ]
            )

        // 18. Freezing(frost) — 아이시 페일 블루
        case "frost":
            return tri(dc("EEF6FC"), dc("C6E0F4"), dc("AECCEA"), dc("E0F0FA"))

        // 19. Starry Night — 딥 네이비 + 골드 문 포인트
        case "clear-night":
            return DraftPalette(
                meshColorsA: [
                    dc("1C2450"), dc("262E6C"), dc("262E6C"),
                    dc("1C2450"), dc("262E6C"), dc("C8A020"),
                    dc("C8A020"), dc("2E3878"), dc("1C2450"),
                    dc("2E3878"), dc("1C2450"), dc("262E6C"),
                    dc("1C2450"), dc("262E6C"), dc("1C2450"),
                ],
                meshColorsB: [
                    dc("1C2450"), dc("C8A020"), dc("262E6C"),
                    dc("262E6C"), dc("2E3878"), dc("1C2450"),
                    dc("1C2450"), dc("262E6C"), dc("2E3878"),
                    dc("262E6C"), dc("1C2450"), dc("C8A020"),
                    dc("262E6C"), dc("1C2450"), dc("1C2450"),
                ]
            )

        // 20. After Rain(showers) — 라이트 민트-그린
        case "showers":
            return tri(dc("EEF8F4"), dc("BCE6D8"), dc("9ED4C4"), dc("DAEFE8"))

        default:
            return tri(dc("FFF8E0"), dc("FCE488"), dc("F8D474"), dc("F8C498"))
        }
    }
}

// MARK: - Preview (10가지 날씨 조건)
// 날씨 변수 매핑:
//   animationDuration ← wind  (바람 셀수록 빠름)
//   blurRadius        ← humidity (습할수록 블러↑)
//   saturationScale   ← cloudCover (구름 많을수록 채도↓)
//   brightnessScale   ← cloudCover (구름 많을수록 밝기↓)
//   hueOffset         ← temperature (기온 높을수록 warm 쪽 미세 이동)

#Preview("① 새벽 맑음") {   // sunrise — ro+yM+pc, 조용한 속도
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 16, weatherCode: 0, windSpeed: 5, humidity: 40, cloudCover: 5),
        hour: 6
    )
}
#Preview("② 맑은 낮") {     // clear-day — 골드+로즈+앰버 (웜)
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 26, weatherCode: 0, windSpeed: 10, humidity: 30, cloudCover: 5),
        hour: 13
    )
}
#Preview("③ 구름 조금") {   // partly-cloudy — 로즈+앰버+살짝쿨블루
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 22, weatherCode: 2, windSpeed: 12, humidity: 45, cloudCover: 35),
        hour: 12
    )
}
#Preview("④ 흐림") {        // cloudy — 그레이블루+라이트블루+아이스
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 18, weatherCode: 3, windSpeed: 10, humidity: 65, cloudCover: 80),
        hour: 14
    )
}
#Preview("⑤ 안개") {        // fog — 거의 화이트, 연한 블루 블롭
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 14, weatherCode: 45, windSpeed: 3, humidity: 95, cloudCover: 90),
        hour: 9
    )
}
#Preview("⑥ 이슬비") {      // drizzle — 라이트블루+소프트블루+아이스
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 15, weatherCode: 53, windSpeed: 8, humidity: 80, cloudCover: 85),
        hour: 11
    )
}
#Preview("⑦ 비") {          // rain — 소프트블루+그레이블루
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 16, weatherCode: 63, windSpeed: 22, humidity: 88, cloudCover: 90),
        hour: 15
    )
}
#Preview("⑧ 천둥번개") {    // thunderstorm — 바이올렛+네이비+딥네이비, 가장 빠름
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 18, weatherCode: 95, windSpeed: 42, humidity: 92, cloudCover: 95),
        hour: 16
    )
}
#Preview("⑨ 눈") {          // snow — 아이스+라이트블루+프로스트화이트
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: -2, weatherCode: 73, windSpeed: 10, humidity: 75, cloudCover: 88),
        hour: 10
    )
}
#Preview("⑩ 맑은 밤") {     // clear-night — 딥네이비+네이비+골드문 포인트
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 12, weatherCode: 0, windSpeed: 4, humidity: 55, cloudCover: 5),
        hour: 23
    )
}
