import SwiftUI

// MARK: - Weather condition

enum WeatherCondition {
    case sunrise, clearDay, partlyCloudy, cloudy
    case overcast, rain, drizzle, thunderstorm
    case snow, blizzard, fog, overcastGrey
    case goldenHour, duskWarm, mistyTeal, dust
    case sunset, clearBlue, night, spring
}

// MARK: - Background entry point

struct WeatherBackground: View {
    let condition: WeatherCondition

    var body: some View {
        GeometryReader { geo in
            let sx = geo.size.width  / 390
            let sy = geo.size.height / 844

            ZStack {
                baseColor
                canvasLayer(sx: sx, sy: sy)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Solid base colour

    @ViewBuilder
    private var baseColor: some View {
        switch condition {
        case .sunrise:       Color(hex: "#FFFAF3")
        case .clearDay:      Color(hex: "#F5F8FC")
        case .partlyCloudy:  Color(hex: "#F5F8FC")
        case .cloudy:        Color(hex: "#EEF4F4")
        case .overcast:      Color(hex: "#EEF2F0")
        case .rain:          Color(hex: "#E4EEF8")
        case .drizzle:       Color(hex: "#F4F6F2")
        case .thunderstorm:  Color(hex: "#46445F")
        case .snow:          Color(hex: "#F5F8FC")
        case .blizzard:      Color(hex: "#DCE4EE")
        case .fog:           Color(hex: "#EEF2F0")
        case .overcastGrey:  Color(hex: "#EEF4F4")
        case .goldenHour:    Color(hex: "#EEF4F4")
        case .duskWarm:      Color(hex: "#E8DED4")
        case .mistyTeal:     Color(hex: "#EEF4F4")
        case .dust:          Color(hex: "#D6CDC1")
        case .sunset:        Color(hex: "#E4EEF8")
        case .clearBlue:     Color(hex: "#E4EEF8")
        case .night:         Color(hex: "#232850")
        case .spring:        Color(hex: "#F4F6F2")
        }
    }

    // MARK: Canvas — draws all gradient layers in one pass

    @ViewBuilder
    private func canvasLayer(sx: CGFloat, sy: CGFloat) -> some View {
        Canvas { ctx, size in
            for layer in gradientLayers.reversed() {
                layer.draw(into: &ctx, size: size, sx: sx, sy: sy)
            }
        }
    }

    // MARK: Layer definitions (CSS order: first = top → reversed for draw order)

    private var gradientLayers: [GradientLayer] {
        switch condition {
        case .sunrise:      return sunriseLayers
        case .clearDay:     return clearDayLayers
        case .partlyCloudy: return partlyCloudyLayers
        case .cloudy:       return cloudyLayers
        case .overcast:     return overcastLayers
        case .rain:         return rainLayers
        case .drizzle:      return drizzleLayers
        case .thunderstorm: return thunderstormLayers
        case .snow:         return snowLayers
        case .blizzard:     return blizzardLayers
        case .fog:          return fogLayers
        case .overcastGrey: return overcastGreyLayers
        case .goldenHour:   return goldenHourLayers
        case .duskWarm:     return duskWarmLayers
        case .mistyTeal:    return mistyTealLayers
        case .dust:         return dustLayers
        case .sunset:       return sunsetLayers
        case .clearBlue:    return clearBlueLayers
        case .night:        return nightLayers
        case .spring:       return springLayers
        }
    }
}

// MARK: - Layer model

enum GradientLayer {
    case radial(r: CGFloat, cx: CGFloat, cy: CGFloat,
                color: Color, opacity: Double, fadeStop: Double)
    case linear(top: Color, bottom: Color)

    func draw(into ctx: inout GraphicsContext, size: CGSize, sx: CGFloat, sy: CGFloat) {
        switch self {
        case .radial(let r, let cx, let cy, let color, let opacity, let fade):
            let scale  = min(sx, sy)
            let radius = r * scale
            let px     = cx * sx
            let py     = cy * sy
            let rect   = CGRect(x: px - radius, y: py - radius,
                                width: radius * 2, height: radius * 2)
            ctx.drawLayer { inner in
                inner.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: color.opacity(opacity), location: 0),
                            .init(color: .clear, location: fade)
                        ]),
                        center: CGPoint(x: px, y: py),
                        startRadius: 0,
                        endRadius: radius
                    )
                )
            }

        case .linear(let top, let bottom):
            let grad = Gradient(colors: [top, bottom])
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(grad,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint:   CGPoint(x: 0, y: size.height))
            )
        }
    }
}

// MARK: - Layer data per condition
// Exact values from Figma SVG export.
// Layer order matches CSS (first = visually top).

private extension WeatherBackground {

    var sunriseLayers: [GradientLayer] { [
        .radial(r: 735.834, cx:  97.5, cy: 675.2, color: .init(red:1.00, green:0.549, blue:0.314), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 650.825, cx: 273.0, cy: 590.8, color: .init(red:1.00, green:0.784, blue:0.392), opacity: 0.60, fadeStop: 0.55),
        .radial(r: 622.149, cx: 195.0, cy: 253.2, color: .init(red:1.00, green:0.882, blue:0.471), opacity: 0.55, fadeStop: 0.65),
        .radial(r: 728.302, cx: 117.0, cy: 168.8, color: .init(red:1.00, green:0.941, blue:0.882), opacity: 0.70, fadeStop: 0.55),
    ] }

    var clearDayLayers: [GradientLayer] { [
        .radial(r: 689.361, cx: 117.0, cy: 211.0, color: .init(red:1.00, green:0.824, blue:0.471), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 584.805, cx: 292.5, cy: 506.4, color: .init(red:1.00, green:0.922, blue:0.745), opacity: 0.70, fadeStop: 0.55),
        .radial(r: 743.800, cx:  78.0, cy: 675.2, color: .init(red:1.00, green:0.784, blue:0.549), opacity: 0.35, fadeStop: 0.60),
        .linear(top: .init(hex: "#F5F8FC"), bottom: .init(hex: "#EEF4F4")),
    ] }

    var partlyCloudyLayers: [GradientLayer] { [
        .radial(r: 659.243, cx:  97.5, cy: 253.2, color: .init(red:0.863, green:0.902, blue:0.941), opacity: 0.70, fadeStop: 0.60),
        .radial(r: 697.313, cx: 292.5, cy: 211.0, color: .init(red:1.00, green:0.882, blue:0.667), opacity: 0.45, fadeStop: 0.55),
        .radial(r: 714.599, cx: 234.0, cy: 675.2, color: .init(red:0.706, green:0.784, blue:0.863), opacity: 0.50, fadeStop: 0.60),
        .linear(top: .init(hex: "#F5F8FC"), bottom: .init(hex: "#EEF4F4")),
    ] }

    var cloudyLayers: [GradientLayer] { [
        .radial(r: 650.825, cx: 117.0, cy: 253.2, color: .init(red:0.863, green:0.882, blue:0.910), opacity: 0.80, fadeStop: 0.60),
        .radial(r: 650.825, cx: 273.0, cy: 590.8, color: .init(red:0.706, green:0.824, blue:0.922), opacity: 0.60, fadeStop: 0.55),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.706, green:0.745, blue:0.784), opacity: 0.50, fadeStop: 0.60),
        .linear(top: .init(hex: "#EEF4F4"), bottom: .init(hex: "#E8E8EB")),
    ] }

    var overcastLayers: [GradientLayer] { [
        .radial(r: 689.361, cx: 117.0, cy: 211.0, color: .init(red:0.863, green:0.706, blue:0.667), opacity: 0.45, fadeStop: 0.60),
        .radial(r: 575.300, cx: 273.0, cy: 506.4, color: .init(red:0.784, green:0.784, blue:0.824), opacity: 0.50, fadeStop: 0.60),
        .radial(r: 784.230, cx: 195.0, cy: 759.6, color: .init(red:0.824, green:0.882, blue:0.941), opacity: 0.70, fadeStop: 0.55),
        .linear(top: .init(hex: "#EEF2F0"), bottom: .init(hex: "#E8E8EB")),
    ] }

    var rainLayers: [GradientLayer] { [
        .radial(r: 689.361, cx: 117.0, cy: 211.0, color: .init(red:0.118, green:0.314, blue:0.745), opacity: 0.50, fadeStop: 0.60),
        .radial(r: 728.302, cx: 273.0, cy: 675.2, color: .init(red:0.863, green:0.902, blue:0.961), opacity: 0.80, fadeStop: 0.60),
        .linear(top: .init(hex: "#EEF4F4"), bottom: .init(hex: "#E4EEF8")),
    ] }

    var drizzleLayers: [GradientLayer] { [
        .radial(r: 650.825, cx: 117.0, cy: 253.2, color: .init(red:0.667, green:0.784, blue:0.863), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 575.300, cx: 273.0, cy: 506.4, color: .init(red:0.784, green:0.863, blue:0.922), opacity: 0.60, fadeStop: 0.60),
        .radial(r: 784.230, cx: 195.0, cy: 759.6, color: .init(red:0.863, green:0.894, blue:0.933), opacity: 0.60, fadeStop: 0.60),
        .linear(top: .init(hex: "#F4F6F2"), bottom: .init(hex: "#E4EEF8")),
    ] }

    var thunderstormLayers: [GradientLayer] { [
        .radial(r: 735.834, cx:  97.5, cy: 168.8, color: .init(red:0.235, green:0.216, blue:0.392), opacity: 0.70, fadeStop: 0.55),
        .radial(r: 584.805, cx: 292.5, cy: 506.4, color: .init(red:0.431, green:0.392, blue:0.588), opacity: 0.60, fadeStop: 0.60),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:1.00, green:0.882, blue:0.471), opacity: 0.25, fadeStop: 0.50),
        .linear(top: .init(hex: "#46445F"), bottom: .init(hex: "#5F5C78")),
    ] }

    var snowLayers: [GradientLayer] { [
        .radial(r: 697.313, cx:  97.5, cy: 211.0, color: .init(red:0.882, green:0.922, blue:0.961), opacity: 0.85, fadeStop: 0.60),
        .radial(r: 650.825, cx: 273.0, cy: 590.8, color: .init(red:0.824, green:0.882, blue:0.941), opacity: 0.70, fadeStop: 0.55),
        .radial(r: 464.875, cx: 195.0, cy: 422.0, color: .init(red:0.961, green:0.980, blue:1.00),  opacity: 0.80, fadeStop: 0.60),
        .linear(top: .init(hex: "#F5F8FC"), bottom: .init(hex: "#EEF2F0")),
    ] }

    var blizzardLayers: [GradientLayer] { [
        .radial(r: 728.302, cx: 117.0, cy: 168.8, color: .init(red:0.706, green:0.784, blue:0.863), opacity: 0.65, fadeStop: 0.55),
        .radial(r: 575.300, cx: 273.0, cy: 506.4, color: .init(red:0.784, green:0.843, blue:0.902), opacity: 0.70, fadeStop: 0.55),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.627, green:0.706, blue:0.784), opacity: 0.50, fadeStop: 0.60),
        .linear(top: .init(hex: "#DCE4EE"), bottom: .init(hex: "#CEDAE8")),
    ] }

    var fogLayers: [GradientLayer] { [
        .radial(r: 659.243, cx:  97.5, cy: 253.2, color: .init(red:0.667, green:0.745, blue:0.843), opacity: 0.60, fadeStop: 0.60),
        .radial(r: 659.243, cx: 292.5, cy: 590.8, color: .init(red:0.784, green:0.824, blue:0.882), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.863, green:0.894, blue:0.933), opacity: 0.60, fadeStop: 0.55),
        .linear(top: .init(hex: "#EEF2F0"), bottom: .init(hex: "#E4EEEE")),
    ] }

    var overcastGreyLayers: [GradientLayer] { [
        .radial(r: 650.825, cx: 117.0, cy: 253.2, color: .init(red:0.824, green:0.824, blue:0.831), opacity: 0.70, fadeStop: 0.60),
        .radial(r: 502.606, cx: 273.0, cy: 422.0, color: .init(red:0.882, green:0.882, blue:0.894), opacity: 0.80, fadeStop: 0.55),
        .radial(r: 784.230, cx: 195.0, cy: 759.6, color: .init(red:0.784, green:0.784, blue:0.804), opacity: 0.55, fadeStop: 0.60),
        .linear(top: .init(hex: "#EEF4F4"), bottom: .init(hex: "#E8E8EB")),
    ] }

    var goldenHourLayers: [GradientLayer] { [
        .radial(r: 659.243, cx:  97.5, cy: 253.2, color: .init(red:1.00, green:0.824, blue:0.667), opacity: 0.50, fadeStop: 0.60),
        .radial(r: 584.805, cx: 292.5, cy: 506.4, color: .init(red:0.941, green:0.843, blue:0.745), opacity: 0.55, fadeStop: 0.55),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.863, green:0.824, blue:0.784), opacity: 0.55, fadeStop: 0.60),
        .linear(top: .init(hex: "#EEF4F4"), bottom: .init(hex: "#E4EEEE")),
    ] }

    var duskWarmLayers: [GradientLayer] { [
        .radial(r: 697.313, cx:  97.5, cy: 211.0, color: .init(red:0.627, green:0.529, blue:0.471), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 584.805, cx: 292.5, cy: 506.4, color: .init(red:0.706, green:0.627, blue:0.569), opacity: 0.55, fadeStop: 0.55),
        .radial(r: 825.172, cx: 195.0, cy: 801.8, color: .init(red:0.784, green:0.706, blue:0.647), opacity: 0.55, fadeStop: 0.60),
        .linear(top: .init(hex: "#E8DED4"), bottom: .init(hex: "#DACEC4")),
    ] }

    var mistyTealLayers: [GradientLayer] { [
        .radial(r: 668.123, cx:  78.0, cy: 253.2, color: .init(red:0.706, green:0.824, blue:0.824), opacity: 0.60, fadeStop: 0.60),
        .radial(r: 513.459, cx: 292.5, cy: 422.0, color: .init(red:0.824, green:0.882, blue:0.882), opacity: 0.60, fadeStop: 0.55),
        .radial(r: 825.172, cx: 195.0, cy: 801.8, color: .init(red:0.784, green:0.863, blue:0.863), opacity: 0.65, fadeStop: 0.60),
        .linear(top: .init(hex: "#EEF4F4"), bottom: .init(hex: "#E4EEEE")),
    ] }

    var dustLayers: [GradientLayer] { [
        .radial(r: 650.825, cx: 117.0, cy: 253.2, color: .init(red:0.471, green:0.424, blue:0.373), opacity: 0.50, fadeStop: 0.55),
        .radial(r: 621.706, cx: 292.5, cy: 548.6, color: .init(red:0.667, green:0.608, blue:0.529), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.549, green:0.510, blue:0.451), opacity: 0.55, fadeStop: 0.60),
        .linear(top: .init(hex: "#D6CDC1"), bottom: .init(hex: "#C4BAAC")),
    ] }

    var sunsetLayers: [GradientLayer] { [
        .radial(r: 697.313, cx:  97.5, cy: 211.0, color: .init(red:1.00, green:0.314, blue:0.196), opacity: 0.60, fadeStop: 0.55),
        .radial(r: 584.805, cx: 292.5, cy: 506.4, color: .init(red:1.00, green:0.588, blue:0.314), opacity: 0.65, fadeStop: 0.55),
        .radial(r: 825.172, cx: 195.0, cy: 801.8, color: .init(red:1.00, green:0.784, blue:0.392), opacity: 0.60, fadeStop: 0.60),
        .linear(top: .init(hex: "#E4EEF8"), bottom: .init(hex: "#FCE4CD")),
    ] }

    var clearBlueLayers: [GradientLayer] { [
        .radial(r: 697.313, cx:  97.5, cy: 211.0, color: .init(red:0.549, green:0.706, blue:0.863), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 621.706, cx: 292.5, cy: 548.6, color: .init(red:0.706, green:0.824, blue:0.922), opacity: 0.60, fadeStop: 0.55),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.784, green:0.882, blue:0.941), opacity: 0.70, fadeStop: 0.60),
        .linear(top: .init(hex: "#E4EEF8"), bottom: .init(hex: "#D6E4F2")),
    ] }

    var nightLayers: [GradientLayer] { [
        .radial(r: 697.313, cx:  97.5, cy: 211.0, color: .init(red:0.196, green:0.235, blue:0.471), opacity: 0.70, fadeStop: 0.55),
        .radial(r: 621.706, cx: 292.5, cy: 548.6, color: .init(red:0.314, green:0.353, blue:0.549), opacity: 0.60, fadeStop: 0.60),
        .radial(r: 825.172, cx: 195.0, cy: 801.8, color: .init(red:0.471, green:0.510, blue:0.667), opacity: 0.50, fadeStop: 0.60),
        .linear(top: .init(hex: "#232850"), bottom: .init(hex: "#373C5F")),
    ] }

    var springLayers: [GradientLayer] { [
        .radial(r: 705.715, cx:  78.0, cy: 211.0, color: .init(red:1.00, green:0.784, blue:0.588), opacity: 0.50, fadeStop: 0.55),
        .radial(r: 464.875, cx: 195.0, cy: 422.0, color: .init(red:0.706, green:0.863, blue:0.784), opacity: 0.55, fadeStop: 0.55),
        .radial(r: 668.123, cx: 312.0, cy: 590.8, color: .init(red:0.706, green:0.784, blue:0.922), opacity: 0.55, fadeStop: 0.60),
        .radial(r: 866.234, cx: 195.0, cy: 844.0, color: .init(red:0.863, green:0.784, blue:0.902), opacity: 0.45, fadeStop: 0.60),
        .linear(top: .init(hex: "#F4F6F2"), bottom: .init(hex: "#EEF2F0")),
    ] }
}
