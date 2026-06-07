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

    @State private var phaseX  = false
    @State private var phaseY  = false
    @State private var turbX   = false
    @State private var turbY   = false
    @State private var pulsed  = false

    private var blobSize: CGFloat {
        max(blob.sizePercent / 100 * size.width, 1)
    }
    private var cx: CGFloat { blob.xPercent  / 100 * size.width  }
    private var cy: CGFloat { blob.yPercent  / 100 * size.height }

    // Primary drift — same elliptical path as before
    private var driftX: CGFloat {
        CGFloat(params.displacementPercent) / 100 * size.width
            * CGFloat(0.5 + 0.5 * cos(Double(index * 137) * .pi / 180))
    }
    private var driftY: CGFloat {
        CGFloat(params.displacementPercent) / 100 * size.height
            * CGFloat(0.5 + 0.5 * sin(Double(index * 137) * .pi / 180))
    }

    // Turbulence — quadratic scaling so high values (0.8+) are dramatically more chaotic
    private var turbAmpX: CGFloat { CGFloat(params.turbulence * params.turbulence) * 0.14 * size.width  }
    private var turbAmpY: CGFloat { CGFloat(params.turbulence * params.turbulence) * 0.14 * size.height }
    private var turbDirX: CGFloat { (index % 2 == 0) ?  1 : -1 }
    private var turbDirY: CGFloat { (index % 3 == 0) ?  1 : -1 }

    private var durationX: Double {
        params.animationDuration * (1.0 + Double(index % 5 - 2) * 0.09)
    }
    private var durationY: Double {
        params.animationDuration * (1.0 + Double(index % 7 - 3) * 0.13)
    }
    private var turbDuration: Double {
        max(1.2, params.animationDuration * 0.20 + Double(index % 4) * 0.35)
    }

    // Pulse — oscillates between 55% and 100% of base opacity
    private var effectiveOpacity: Double {
        guard params.pulseEnabled else { return params.orbOpacity }
        return params.orbOpacity * (pulsed ? 1.0 : 0.55)
    }

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        blob.startColor.opacity(effectiveOpacity),
                        blob.endColor.opacity(effectiveOpacity * 0.3),
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
                x: cx
                    + (phaseX ? driftX : -driftX)
                    + (turbX  ? turbAmpX * turbDirX : 0),
                y: cy
                    + (phaseY ? driftY : -driftY)
                    + (turbY  ? turbAmpY * turbDirY : 0)
            )
            .onAppear { startAnimations() }
    }

    private func startAnimations() {
        let sx = Double(index % 5) * 0.25
        let sy = Double(index % 7) * 0.20
        let st = Double(index % 3) * 0.15

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(sx))
            withAnimation(.easeInOut(duration: durationX).repeatForever(autoreverses: true)) {
                phaseX = true
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(sy))
            withAnimation(.easeInOut(duration: durationY).repeatForever(autoreverses: true)) {
                phaseY = true
            }
        }

        if params.turbulence > 0.05 {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(st))
                withAnimation(.easeInOut(duration: turbDuration).repeatForever(autoreverses: true)) {
                    turbX = true
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(st + 0.12))
                withAnimation(.easeInOut(duration: turbDuration * 1.35).repeatForever(autoreverses: true)) {
                    turbY = true
                }
            }
        }

        if params.pulseEnabled {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Double(index % 5) * 0.10))
                withAnimation(.easeInOut(duration: 0.6 + Double(index % 3) * 0.2).repeatForever(autoreverses: true)) {
                    pulsed = true
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
