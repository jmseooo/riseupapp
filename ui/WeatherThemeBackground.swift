import SwiftUI

// MARK: - WeatherThemeBackground

struct WeatherThemeBackground: View {
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
            wmoCode:     wmo,
            temperature: temp,
            humidity:    humid,
            windSpeed:   wind,
            cloudCover:  cloud,
            hour:        hour,
            launchSeed:  launchSeed
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundGradient
                ForEach(0..<params.blobs.count, id: \.self) { i in
                    AnimatedBlob(
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

// MARK: - AnimatedBlob

private struct AnimatedBlob: View {
    let blob:   BlobParams
    let params: WeatherVisualParams
    let size:   CGSize
    let index:  Int

    @State private var phase = false

    private var blobSize: CGFloat {
        max(blob.sizePercent / 100 * size.width, 1)
    }
    private var cx: CGFloat { blob.xPercent / 100 * size.width }
    private var cy: CGFloat { blob.yPercent / 100 * size.height }

    // blob마다 황금각(137°) 간격으로 다른 방향
    private var driftAngle: Double {
        Double(index * 137 + Int(blob.xPercent * 7 + blob.yPercent * 3)) * .pi / 180
    }
    private var driftX: CGFloat {
        cos(driftAngle) * CGFloat(params.displacementPercent) / 100 * size.width
    }
    private var driftY: CGFloat {
        sin(driftAngle) * CGFloat(params.displacementPercent) / 100 * size.height
    }

    // blob마다 주기 미세 차이 → 자연스럽게 탈동기화
    private var duration: Double {
        params.animationDuration * (1.0 + Double(index % 7 - 3) * 0.08)
    }

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        blob.startColor.opacity(params.orbOpacity),
                        blob.endColor.opacity(params.orbOpacity * 0.3),
                        .clear
                    ],
                    center:      .center,
                    startRadius: 0,
                    endRadius:   blobSize / 2
                )
            )
            .frame(width: blobSize, height: blobSize)
            .blur(radius: params.blurRadius)
            .hueRotation(.degrees(params.hueOffset))
            .brightness(params.brightnessScale - 1.0)
            .saturation(params.saturationScale)
            .position(
                x: cx + (phase ? driftX : -driftX),
                y: cy + (phase ? driftY : -driftY)
            )
            .onAppear {
                let stagger = Double(index % 5) * 0.3
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(stagger))
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        phase = true
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    WeatherThemeBackground(
        weather: WeatherData(
            temperature: 22,
            weatherCode: 61,
            windSpeed:   18,
            humidity:    72,
            cloudCover:  80
        ),
        hour: 14
    )
}
