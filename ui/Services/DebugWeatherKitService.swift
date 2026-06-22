#if DEBUG
import WeatherKit
import CoreLocation

@Observable
final class DebugWeatherKitService {
    static let shared = DebugWeatherKitService()

    var temperature: Double?
    var weatherCode: Int?
    var windSpeed: Double?
    var humidity: Int?
    var cloudCover: Int?
    var sunriseToday: Date?
    var lastError: String?

    private init() {}

    func fetch(latitude: Double, longitude: Double) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(
                for: location,
                including: .current, .daily
            )
            let c = weather.0
            let daily = weather.1
            let cal = Calendar.current

            temperature  = c.temperature.converted(to: .celsius).value
            weatherCode  = conditionToWMO(c.condition)
            windSpeed    = c.wind.speed.converted(to: .kilometersPerHour).value
            humidity     = Int((c.humidity * 100).rounded())
            cloudCover   = Int((c.cloudCover * 100).rounded())
            sunriseToday = daily.first(where: { cal.isDateInToday($0.date) })?.sun.sunrise
            lastError    = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func conditionToWMO(_ condition: WeatherKit.WeatherCondition) -> Int {
        switch condition {
        case .clear:               return 0
        case .mostlyClear:         return 1
        case .partlyCloudy:        return 2
        case .mostlyCloudy, .cloudy: return 3
        case .foggy:               return 45
        case .haze:                return 5
        case .drizzle:             return 51
        case .rain:                return 61
        case .heavyRain:           return 65
        case .sunShowers:          return 80
        case .freezingDrizzle:     return 56
        case .freezingRain:        return 66
        case .sleet, .wintryMix:   return 77
        case .flurries, .snow, .sunFlurries: return 71
        case .heavySnow, .blowingSnow, .blizzard: return 75
        case .hail:                return 96
        case .isolatedThunderstorms, .thunderstorms, .scatteredThunderstorms: return 95
        case .strongStorms, .tropicalStorm, .hurricane: return 99
        default:                   return 0
        }
    }
}
#endif
