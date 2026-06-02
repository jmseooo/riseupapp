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

// MARK: - 테마별 포인트 컬러 (blob 4개 중 1개에만 적용)
// 기존 warm/yellow 계열을 유지하면서 조화로운 악센트 하나를 섞음

private let pointColors: [String: (Color, Color)] = [
    // 새벽 — 소프트로즈 (따뜻한 새벽빛)
    "sunrise":       (dc("F0C8C0"), dc("D8A8A0")),
    // 맑은 낮 — 연피치 (따뜻한 햇살)
    "clear-day":     (dc("F0D0B8"), dc("D8B098")),
    // 구름 조금 — 웜베이지 (햇빛 사이 구름)
    "partly-cloudy": (dc("F0D8C8"), dc("D8B8A8")),
    "cloudy":        (dc("E8D0C0"), dc("D0B0A0")),
    "overcast":      (dc("E0C8C0"), dc("C8A8A0")),
    // 비 — 쿨라벤더 (빗속 보라빛, 차갑지만 무겁지 않게)
    "rain":          (dc("D0C8E0"), dc("B0A8C8")),
    "showers":       (dc("C8C0D8"), dc("A8A0C0")),
    "drizzle":       (dc("D0C8D8"), dc("B0A8C0")),
    // 눈 — 아이시핑크 (눈 속의 따뜻한 기운)
    "snow":          (dc("F0D8E0"), dc("D8B8C8")),
    "blizzard":      (dc("E8D0D8"), dc("D0B0C0")),
    "frost":         (dc("E0D0D8"), dc("C8B0C0")),
    // 밤 — 딥로즈 (밤하늘의 붉은 기운)
    "clear-night":   (dc("C8A0B0"), dc("A88090")),
    // 천둥 — 전기옐로우 (번개빛)
    "thunderstorm":  (dc("F0E8A0"), dc("D8D080")),
    // 연무·황사 — 웜샌드 (탁한 하늘)
    "hazy":          (dc("F0D8B8"), dc("D8B898")),
    "mist":          (dc("E8D8C8"), dc("D0B8A8")),
    "dust":          (dc("E8D0B0"), dc("D0B090")),
    "sandstorm":     (dc("E0C8A8"), dc("C8A888")),
    // 바람 — 연민트 (신선한 바람)
    "windy":         (dc("C8E8D8"), dc("A8D0B8")),
    // 열파 — 핫코랄 (뜨거운 열기)
    "heat":          (dc("F0A898"), dc("D88878")),
]

// MARK: - Draft_WeatherThemeBackground

struct Draft_WeatherThemeBackground: View {
    let weather: WeatherData?
    let hour: Int

    @State private var launchSeed = UUID().hashValue

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
        GeometryReader { geo in
            ZStack {
                backgroundGradient
                ForEach(0..<params.blobs.count, id: \.self) { i in
                    DraftAnimatedBlob(
                        blob:   params.blobs[i],
                        params: params,
                        size:   geo.size,
                        index:  i
                    )
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
    }

    private var backgroundGradient: some View {
        let rad = (params.theme.backgroundAngle + params.gradientAngleOffset) * .pi / 180
        return LinearGradient(
            colors: [params.theme.backgroundStart, params.theme.backgroundEnd],
            startPoint: UnitPoint(x: 0.5 - sin(rad) / 2, y: 0.5 - cos(rad) / 2),
            endPoint:   UnitPoint(x: 0.5 + sin(rad) / 2, y: 0.5 + cos(rad) / 2)
        )
        .ignoresSafeArea()
    }
}

// MARK: - DraftAnimatedBlob

private struct DraftAnimatedBlob: View {
    let blob:   BlobParams
    let params: WeatherVisualParams
    let size:   CGSize
    let index:  Int

    @State private var phaseX = false
    @State private var phaseY = false
    @State private var breathScale:     CGFloat = 1.0
    @State private var dissolveScale:   CGFloat = 1.0
    @State private var dissolveOpacity: Double  = 1.0
    @State private var wanderX:         CGFloat = 0
    @State private var wanderY:         CGFloat = 0

    private var blobSize: CGFloat { max(blob.sizePercent / 100 * size.width * 1.5, 1) }
    private var cx: CGFloat { blob.xPercent  / 100 * size.width  }
    private var cy: CGFloat { blob.yPercent  / 100 * size.height }

    // 이동은 보조 — 화면의 25% 범위 내 완만한 drift
    private var driftX: CGFloat {
        size.width  * 0.25 * CGFloat(0.6 + 0.4 * cos(Double(index * 137) * .pi / 180))
    }
    private var driftY: CGFloat {
        size.height * 0.20 * CGFloat(0.6 + 0.4 * sin(Double(index * 137) * .pi / 180))
    }

    private var activeDur: Double { params.animationDuration }
    private var durationX: Double { params.animationDuration * 1.1 * (1.0 + Double(index % 5 - 2) * 0.09) }
    private var durationY: Double { params.animationDuration * 1.1 * (1.0 + Double(index % 7 - 3) * 0.13) }

    private var effectiveBlur: CGFloat { params.blurRadius * 1.4 }

    private var isPointBlob: Bool { index % 4 == 3 }

    private var orbColors: (start: Color, end: Color) {
        if isPointBlob, let point = pointColors[params.theme.id] {
            return point
        }
        return (blob.endColor, blob.startColor)
    }

    var body: some View {
        let colors = orbColors
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        colors.start.opacity(params.orbOpacity * dissolveOpacity),
                        colors.end.opacity(params.orbOpacity * 0.2 * dissolveOpacity),
                        .clear
                    ],
                    center:      .center,
                    startRadius: 0,
                    endRadius:   blobSize / 2
                )
            )
            .frame(width: blobSize * dissolveScale, height: blobSize * dissolveScale)
            .blur(radius: effectiveBlur + (dissolveScale - 1.0) * effectiveBlur * 1.5)
            .hueRotation(.degrees(params.hueOffset))
            .brightness(params.brightnessScale - 1.0)
            .saturation(params.saturationScale * 1.3)
            .position(
                x: cx + wanderX + (phaseX ? driftX : -driftX),
                y: cy + wanderY + (phaseY ? driftY : -driftY)
            )
            .onAppear {
                // 이동: 모든 blob, 느리게 (보조)
                startFloat()
                // 퍼지며 흩어짐: 4개 주기 내에서 시차, 여러 blob 동시 활성화
                let dissolveDelay = Double(index % 4) * 0.5
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(dissolveDelay))
                    await dissolveLoop()
                }
            }
    }

    private func startFloat() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Double(index % 5) * 0.3))
            withAnimation(.easeInOut(duration: durationX).repeatForever(autoreverses: true)) { phaseX = true }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Double(index % 7) * 0.25))
            withAnimation(.easeInOut(duration: durationY).repeatForever(autoreverses: true)) { phaseY = true }
        }
    }

    // 3개 중 1개(index % 3 == 1)는 보이면서 천천히 이동하는 traveler
    private var isTraveler: Bool { index % 3 == 1 }

    @MainActor
    private func dissolveLoop() async {
        var cycle = 0
        while !Task.isCancelled {
            // hold — 긴 시간 유지해 여러 blob이 동시에 보이도록
            let holdDur = 3.0 + Double(index % 4) * 0.6

            if isTraveler {
                // 선명하게 보이는 동안 다른 위치로 유려하게 이동
                let midAngle = Double(cycle * 89 + index * 71)
                let midX = size.width  * 0.20 * cos(midAngle * .pi / 180)
                let midY = size.height * 0.16 * sin(midAngle * .pi / 180)
                withAnimation(.easeInOut(duration: holdDur)) {
                    wanderX = midX
                    wanderY = midY
                }
            }
            try? await Task.sleep(for: .seconds(holdDur))

            // 다음 등장 위치 — 사이클·인덱스 조합으로 화면 전체에 분산
            let angle = Double(cycle * 137 + index * 53)
            let nextWX = size.width  * 0.22 * cos(angle * .pi / 180)
            let nextWY = size.height * 0.18 * sin(angle * .pi / 180)

            // spread — 짧게, 금방 사라지고 새 위치로 이동
            let spreadDur = 1.2 + Double(index % 3) * 0.25
            withAnimation(.easeInOut(duration: spreadDur)) {
                dissolveScale   = 2.8
                dissolveOpacity = 0.0
                wanderX = nextWX
                wanderY = nextWY
            }
            try? await Task.sleep(for: .seconds(spreadDur))

            // 씨앗 상태 리셋 — 새 위치에서, 불투명도 0이라 안 보임
            dissolveScale   = 0.4
            dissolveOpacity = 0.0

            // emerge — 짧게 솟아오름
            let emergeDur = 0.7 + Double(index % 3) * 0.15
            withAnimation(.easeOut(duration: emergeDur)) {
                dissolveScale   = 1.0
                dissolveOpacity = 1.0
            }
            try? await Task.sleep(for: .seconds(emergeDur))

            cycle += 1
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
