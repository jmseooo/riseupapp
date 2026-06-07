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

// MARK: - Draft Palette (ref2 색 조합 기반)

private struct DraftPalette {
    let meshColorsA: [Color]
    let meshColorsB: [Color]

    static func palette(for themeId: String) -> DraftPalette {
        switch themeId {

        case "sunrise":
            return DraftPalette(
                meshColorsA: [
                    dc("FFE566"), dc("B8E070"), dc("FFD040"),
                    dc("FFE566"), dc("D068A8"), dc("E060C0"),
                    dc("FFD040"), dc("7022C0"), dc("D450A8"),
                    dc("FFE566"), dc("E060C0"), dc("7022C0"),
                    dc("FFD040"), dc("FFE566"), dc("FFD040"),
                ],
                meshColorsB: [
                    dc("B8E070"), dc("FFE566"), dc("FFD040"),
                    dc("E060C0"), dc("FFD040"), dc("B8E070"),
                    dc("D450A8"), dc("FFE566"), dc("7022C0"),
                    dc("7022C0"), dc("D068A8"), dc("FFD040"),
                    dc("FFE566"), dc("FFD040"), dc("FFE566"),
                ]
            )

        case "clear-day":
            return DraftPalette(
                meshColorsA: [
                    dc("FFE566"), dc("FFD040"), dc("C8E870"),
                    dc("FFE566"), dc("8850D0"), dc("FFD040"),
                    dc("FFD040"), dc("FFE566"), dc("9B60E0"),
                    dc("FFD040"), dc("B8E070"), dc("FFE566"),
                    dc("FFE566"), dc("FFD040"), dc("FFE566"),
                ],
                meshColorsB: [
                    dc("C8E870"), dc("FFE566"), dc("FFD040"),
                    dc("FFD040"), dc("FFE566"), dc("8850D0"),
                    dc("9B60E0"), dc("FFD040"), dc("FFE566"),
                    dc("FFE566"), dc("FFD040"), dc("C8E870"),
                    dc("FFD040"), dc("FFE566"), dc("FFD040"),
                ]
            )

        case "partly-cloudy":
            return DraftPalette(
                meshColorsA: [
                    dc("FFE566"), dc("FFD040"), dc("D068A8"),
                    dc("D068A8"), dc("FFE566"), dc("8850D0"),
                    dc("FFD040"), dc("8850D0"), dc("FFE566"),
                    dc("FFE566"), dc("D068A8"), dc("FFD040"),
                    dc("FFD040"), dc("FFE566"), dc("FFD040"),
                ],
                meshColorsB: [
                    dc("D068A8"), dc("FFE566"), dc("FFD040"),
                    dc("8850D0"), dc("FFD040"), dc("D068A8"),
                    dc("FFE566"), dc("D068A8"), dc("8850D0"),
                    dc("FFD040"), dc("FFE566"), dc("D068A8"),
                    dc("FFE566"), dc("FFD040"), dc("FFE566"),
                ]
            )

        case "rain", "drizzle", "showers":
            return DraftPalette(
                meshColorsA: [
                    dc("FFD040"), dc("3D1880"), dc("FFE566"),
                    dc("FFE566"), dc("5525A0"), dc("3D1880"),
                    dc("FFD040"), dc("8022C0"), dc("FFE566"),
                    dc("7022C0"), dc("FFD040"), dc("5525A0"),
                    dc("FFE566"), dc("FFD040"), dc("FFE566"),
                ],
                meshColorsB: [
                    dc("3D1880"), dc("FFE566"), dc("FFD040"),
                    dc("FFD040"), dc("3D1880"), dc("FFE566"),
                    dc("FFE566"), dc("7022C0"), dc("FFD040"),
                    dc("5525A0"), dc("FFE566"), dc("8022C0"),
                    dc("FFD040"), dc("FFE566"), dc("FFD040"),
                ]
            )

        case "clear-night":
            return DraftPalette(
                meshColorsA: [
                    dc("271161"), dc("FFD040"), dc("180E50"),
                    dc("FFD040"), dc("7022C0"), dc("3D1880"),
                    dc("FFB830"), dc("4A2EA0"), dc("FFD040"),
                    dc("7022C0"), dc("FFD040"), dc("3D1880"),
                    dc("180E50"), dc("FFD040"), dc("271161"),
                ],
                meshColorsB: [
                    dc("180E50"), dc("FFD040"), dc("271161"),
                    dc("3D1880"), dc("FFD040"), dc("7022C0"),
                    dc("FFD040"), dc("4A2EA0"), dc("FFB830"),
                    dc("3D1880"), dc("FFD040"), dc("7022C0"),
                    dc("271161"), dc("FFD040"), dc("180E50"),
                ]
            )

        case "thunderstorm":
            return DraftPalette(
                meshColorsA: [
                    dc("1A0840"), dc("FFE566"), dc("2D1060"),
                    dc("FFE566"), dc("8022E0"), dc("1A0840"),
                    dc("FFD040"), dc("A023D0"), dc("7022C0"),
                    dc("FFE566"), dc("7022C0"), dc("FFD040"),
                    dc("2D1060"), dc("FFE566"), dc("1A0840"),
                ],
                meshColorsB: [
                    dc("FFE566"), dc("1A0840"), dc("FFD040"),
                    dc("1A0840"), dc("FFE566"), dc("8022E0"),
                    dc("7022C0"), dc("FFD040"), dc("A023D0"),
                    dc("FFD040"), dc("FFE566"), dc("7022C0"),
                    dc("FFE566"), dc("2D1060"), dc("FFE566"),
                ]
            )

        case "snow", "blizzard", "frost":
            return DraftPalette(
                meshColorsA: [
                    dc("FFE566"), dc("EEF0FF"), dc("FFD040"),
                    dc("8850D0"), dc("FFE566"), dc("C0C8FF"),
                    dc("FFD040"), dc("D0D8FF"), dc("FFE566"),
                    dc("9B60E0"), dc("FFE566"), dc("FFD040"),
                    dc("FFE566"), dc("EEF0FF"), dc("FFD040"),
                ],
                meshColorsB: [
                    dc("EEF0FF"), dc("FFE566"), dc("FFD040"),
                    dc("FFE566"), dc("8850D0"), dc("EEF0FF"),
                    dc("D0D8FF"), dc("FFE566"), dc("9B60E0"),
                    dc("FFE566"), dc("FFD040"), dc("D0D8FF"),
                    dc("FFD040"), dc("FFE566"), dc("EEF0FF"),
                ]
            )

        default:
            return DraftPalette(
                meshColorsA: [
                    dc("FFE566"), dc("FFD040"), dc("D068A8"),
                    dc("FFD040"), dc("8850D0"), dc("FFE566"),
                    dc("E060C0"), dc("FFE566"), dc("FFD040"),
                    dc("FFD040"), dc("D068A8"), dc("8850D0"),
                    dc("FFE566"), dc("FFD040"), dc("FFE566"),
                ],
                meshColorsB: [
                    dc("D068A8"), dc("FFE566"), dc("FFD040"),
                    dc("FFE566"), dc("FFD040"), dc("8850D0"),
                    dc("FFD040"), dc("E060C0"), dc("FFE566"),
                    dc("8850D0"), dc("FFE566"), dc("FFD040"),
                    dc("FFD040"), dc("FFE566"), dc("D068A8"),
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
