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

    @State private var phaseX = false
    @State private var phaseY = false

    private var blobSize: CGFloat {
        max(blob.sizePercent / 100 * size.width, 1)
    }
    private var cx: CGFloat { blob.xPercent / 100 * size.width }
    private var cy: CGFloat { blob.yPercent / 100 * size.height }

    private var driftX: CGFloat {
        CGFloat(params.displacementPercent) / 100 * size.width
            * CGFloat(0.5 + 0.5 * cos(Double(index * 137) * .pi / 180))
    }
    private var driftY: CGFloat {
        CGFloat(params.displacementPercent) / 100 * size.height
            * CGFloat(0.5 + 0.5 * sin(Double(index * 137) * .pi / 180))
    }

    // X/Y 주기를 다르게 → 타원형으로 둥둥 떠다니는 효과
    private var durationX: Double {
        params.animationDuration * (1.0 + Double(index % 5 - 2) * 0.09)
    }
    private var durationY: Double {
        params.animationDuration * (1.0 + Double(index % 7 - 3) * 0.13)
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
                x: cx + (phaseX ? driftX : -driftX),
                y: cy + (phaseY ? driftY : -driftY)
            )
            .onAppear {
                let staggerX = Double(index % 5) * 0.25
                let staggerY = Double(index % 7) * 0.2
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(staggerX))
                    withAnimation(.easeInOut(duration: durationX).repeatForever(autoreverses: true)) {
                        phaseX = true
                    }
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(staggerY))
                    withAnimation(.easeInOut(duration: durationY).repeatForever(autoreverses: true)) {
                        phaseY = true
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
