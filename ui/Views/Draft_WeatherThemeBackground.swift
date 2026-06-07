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

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if #available(iOS 18.0, *) {
                    DraftMeshBackground(themeId: themeId, size: geo.size)
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

    @State private var q1 = false
    @State private var q2 = false
    @State private var q3 = false
    @State private var r1 = false
    @State private var r2 = false
    @State private var colorPhase = false

    private var palette: DraftPalette { DraftPalette.palette(for: themeId) }

    private var meshPoints: [SIMD2<Float>] {
        let cx1: Float = q1 ? 0.62 : 0.38
        let cx2: Float = q2 ? 0.32 : 0.68
        let cx3: Float = q3 ? 0.58 : 0.42
        let dy1: Float = r1 ?  0.03 : -0.03
        let dy2: Float = r2 ? -0.04 :  0.04
        return [
            [0.0, 0.00], [0.50, 0.00],        [1.0, 0.00],
            [0.0, 0.25], [cx1,  0.25 + dy1],  [1.0, 0.25],
            [0.0, 0.50], [cx2,  0.50 + dy2],  [1.0, 0.50],
            [0.0, 0.75], [cx3,  0.75 + dy1],  [1.0, 0.75],
            [0.0, 1.00], [0.50, 1.00],         [1.0, 1.00],
        ]
    }

    var body: some View {
        MeshGradient(
            width: 3, height: 5,
            points: meshPoints,
            colors: colorPhase ? palette.meshColorsB : palette.meshColorsA,
            smoothsColors: true
        )
        .ignoresSafeArea()
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration:  9.0).repeatForever(autoreverses: true))               { q1 = true }
        withAnimation(.easeInOut(duration: 13.0).repeatForever(autoreverses: true).delay(1.5))   { q2 = true }
        withAnimation(.easeInOut(duration: 11.0).repeatForever(autoreverses: true).delay(0.7))   { q3 = true }
        withAnimation(.easeInOut(duration:  7.0).repeatForever(autoreverses: true).delay(2.0))   { r1 = true }
        withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true).delay(0.4))   { r2 = true }
        withAnimation(.easeInOut(duration: 20.0).repeatForever(autoreverses: true).delay(4.0))   { colorPhase = true }
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

// MARK: - Draft Palette ("Rise Daybreak" 영상 픽셀 직접 추출)
//
// 샘플링 좌표별 평균값:
//   cr = #FFF5CC  크림베이스   — 상단 밝은 영역 (Frame2,3,5 top)
//   yL = #FDF0C0  라이트버터   — 상단 중간 영역
//   yM = #FAD28A  골든옐로우   — 중심 주인공 블롭 (Frame2-6 center)
//   yD = #F8BA80  딥앰버피치   — yM과 pc 사이 전환
//   am = #F8D8A8  웜앰버크림   — 중간 전환 영역
//   pc = #F5BEA0  소프트피치   — 하단 전환색 (Frame3 bot-right)
//   co = #F2A898  소프트코랄   — 하단 코너 (Frame4,6 bot-right 계열)
//   ro = #F4B8C8  소프트로즈   — 핑크 블롭 (Frame1 top-center, Frame2,5,6 top-right)

private struct DraftPalette {
    let meshColorsA: [Color]
    let meshColorsB: [Color]

    private static let cr = dc("FFF5CC")   // 크림베이스
    private static let yL = dc("FDF0C0")   // 라이트버터
    private static let yM = dc("FAD28A")   // 골든옐로우 (메인 블롭)
    private static let yD = dc("F8BA80")   // 딥앰버피치
    private static let am = dc("F8D8A8")   // 웜앰버크림
    private static let pc = dc("F5BEA0")   // 소프트피치
    private static let co = dc("F2A898")   // 소프트코랄
    private static let ro = dc("F4B8C8")   // 소프트로즈 (핑크 블롭)

    static func palette(for themeId: String) -> DraftPalette {
        let cr = Self.cr, yL = Self.yL, yM = Self.yM, yD = Self.yD
        let am = Self.am, pc = Self.pc, co = Self.co, ro = Self.ro

        switch themeId {

        // 새벽 — 웜로즈(상단) ↔ 코랄(상단) 대각 반전
        // A: 로즈가 상단-좌, 코랄이 하단-우 / B: 반전
        case "sunrise":
            return DraftPalette(
                meshColorsA: [
                    ro,   cr,   pc,
                    cr,   pc,   ro,
                    pc,   co,   cr,
                    co,   cr,   ro,
                    pc,   co,   ro,
                ],
                meshColorsB: [
                    pc,   cr,   ro,
                    ro,   co,   cr,
                    co,   cr,   pc,
                    cr,   ro,   co,
                    ro,   pc,   co,
                ]
            )

        // 맑은 낮 — 라임옐로우(상단-좌) ↔ 골든앰버(상단-좌) 대각 반전
        // 애니메이션: 라임→골드 블롭이 대각으로 이동
        case "clear-day":
            return DraftPalette(
                meshColorsA: [
                    yM,   cr,   am,
                    cr,   yL,   yM,
                    yL,   yM,   yD,
                    yM,   yD,   cr,
                    yD,   am,   yM,
                ],
                meshColorsB: [
                    am,   cr,   yM,
                    yM,   yL,   cr,
                    yD,   yM,   yL,
                    cr,   yL,   yD,
                    yM,   yD,   am,
                ]
            )

        // 구름 조금 — 앰버크림(상단) ↔ 피치(상단) 반전
        case "partly-cloudy":
            return DraftPalette(
                meshColorsA: [
                    am,   yL,   pc,
                    yL,   yM,   am,
                    am,   cr,   yM,
                    pc,   am,   yL,
                    yL,   pc,   am,
                ],
                meshColorsB: [
                    pc,   yL,   am,
                    am,   yM,   yL,
                    yM,   cr,   am,
                    am,   yL,   pc,
                    am,   yM,   pc,
                ]
            )

        // 흐림 — 크림+피치+앰버 (차분, 애니메이션은 피치 블롭 이동)
        case "cloudy", "overcast":
            return DraftPalette(
                meshColorsA: [
                    cr,   am,   pc,
                    am,   yL,   cr,
                    pc,   cr,   am,
                    cr,   pc,   yL,
                    am,   cr,   am,
                ],
                meshColorsB: [
                    pc,   cr,   am,
                    cr,   pc,   am,
                    am,   yL,   cr,
                    pc,   am,   cr,
                    cr,   am,   pc,
                ]
            )

        // 비 — 코랄+앰버+크림 (웜 빗빛, 코랄 블롭 이동)
        case "rain", "drizzle", "showers":
            return DraftPalette(
                meshColorsA: [
                    co,   am,   cr,
                    am,   pc,   co,
                    cr,   co,   am,
                    co,   cr,   pc,
                    am,   co,   cr,
                ],
                meshColorsB: [
                    cr,   am,   co,
                    co,   cr,   am,
                    am,   pc,   cr,
                    cr,   co,   am,
                    co,   cr,   am,
                ]
            )

        // 밤 — 딥 웜브라운 + 골드 포인트
        case "clear-night":
            return DraftPalette(
                meshColorsA: [
                    dc("281408"),  dc("D4A020"),  dc("1C0C04"),
                    dc("D4A020"),  dc("503018"),  dc("281408"),
                    dc("C89018"),  dc("402010"),  dc("D4A020"),
                    dc("503018"),  dc("D4A020"),  dc("281408"),
                    dc("1C0C04"),  dc("D4A020"),  dc("281408"),
                ],
                meshColorsB: [
                    dc("1C0C04"),  dc("C89018"),  dc("281408"),
                    dc("281408"),  dc("D4A020"),  dc("503018"),
                    dc("D4A020"),  dc("503018"),  dc("C89018"),
                    dc("281408"),  dc("503018"),  dc("D4A020"),
                    dc("281408"),  dc("C89018"),  dc("1C0C04"),
                ]
            )

        // 천둥 — 딥 웜브라운 + 밝은 골드 (골드 블롭 이동)
        case "thunderstorm":
            return DraftPalette(
                meshColorsA: [
                    dc("180C04"),  yM,            dc("200E04"),
                    yM,            dc("5C3010"),  dc("180C04"),
                    yD,            dc("6C3C14"),  dc("5C3010"),
                    yM,            dc("5C3010"),  yD,
                    dc("200E04"),  yM,            dc("180C04"),
                ],
                meshColorsB: [
                    yM,            dc("180C04"),  yD,
                    dc("180C04"),  yD,            dc("5C3010"),
                    dc("5C3010"),  yM,            dc("6C3C14"),
                    yD,            dc("180C04"),  yM,
                    yM,            dc("200E04"),  yM,
                ]
            )

        // 눈·서리 — 크림+버터+로즈 (따뜻한 눈빛)
        case "snow", "blizzard", "frost":
            return DraftPalette(
                meshColorsA: [
                    cr,   ro,   yL,
                    ro,   cr,   ro,
                    yL,   cr,   yL,
                    cr,   yL,   ro,
                    yL,   cr,   yL,
                ],
                meshColorsB: [
                    yL,   cr,   ro,
                    cr,   ro,   cr,
                    ro,   yL,   cr,
                    yL,   ro,   cr,
                    cr,   yL,   cr,
                ]
            )

        // 기타
        default:
            return DraftPalette(
                meshColorsA: [
                    am,   pc,   yM,
                    pc,   yM,   cr,
                    yM,   yD,   am,
                    am,   pc,   yM,
                    yM,   am,   yM,
                ],
                meshColorsB: [
                    pc,   am,   yM,
                    yM,   cr,   pc,
                    yD,   yM,   am,
                    pc,   yM,   am,
                    am,   yM,   am,
                ]
            )
        }
    }
}

// MARK: - Preview

#Preview("Sunrise") {
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 18, weatherCode: 0, windSpeed: 5, humidity: 40, cloudCover: 10),
        hour: 6
    )
}
#Preview("Clear Day") {
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 24, weatherCode: 0, windSpeed: 8, humidity: 35, cloudCover: 5),
        hour: 13
    )
}
#Preview("Rain") {
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 16, weatherCode: 61, windSpeed: 20, humidity: 85, cloudCover: 90),
        hour: 15
    )
}
#Preview("Night") {
    Draft_WeatherThemeBackground(
        weather: WeatherData(temperature: 12, weatherCode: 0, windSpeed: 3, humidity: 50, cloudCover: 5),
        hour: 23
    )
}
