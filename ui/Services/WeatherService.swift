import WeatherKit
import CoreLocation
import Foundation

struct WeatherData {
    let temperature: Double  // °C
    let weatherCode: Int     // WMO-mapped from WeatherCondition
    let windSpeed: Double    // km/h
    let humidity: Int        // %
    let cloudCover: Int      // %
}

@Observable
final class WeatherService {
    static let shared = WeatherService()

    var current: WeatherData?
    var sunriseToday: Date?
    var sunriseTomorrow: Date?
    var utcOffsetSeconds: Int?
    var isLoading = false
    var lastError: String?
    var attribution: WeatherAttribution?

    private init() {
        Task { attribution = try? await WeatherKit.WeatherService.shared.attribution }
    }

    func fetch(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(
                for: location,
                including: .current, .daily
            )
            let c = weather.0
            let daily = weather.1

            print("[WeatherService] temp: \(c.temperature), condition: \(c.condition)")

            current = WeatherData(
                temperature: c.temperature.converted(to: .celsius).value,
                weatherCode: conditionToWMO(c.condition),
                windSpeed: c.wind.speed.converted(to: .kilometersPerHour).value,
                humidity: Int((c.humidity * 100).rounded()),
                cloudCover: Int((c.cloudCover * 100).rounded())
            )

            let cal = Calendar.current
            let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
            sunriseToday    = daily.first(where: { cal.isDateInToday($0.date) })?.sun.sunrise
            sunriseTomorrow = daily.first(where: { cal.isDate($0.date, inSameDayAs: tomorrow) })?.sun.sunrise

            utcOffsetSeconds = TimeZone.current.secondsFromGMT()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            print("[WeatherService] fetch error: \(error.localizedDescription)")
        }
    }

    private func conditionToWMO(_ condition: WeatherKit.WeatherCondition) -> Int {
        switch condition {
        case .clear:                                                     return 0
        case .mostlyClear:                                               return 1
        case .breezy, .windy:                                            return 200
        case .smoky:                                                     return 201
        case .blowingDust:                                               return 202
        case .hot:                                                       return 203
        case .frigid:                                                    return 204
        case .partlyCloudy:                                              return 2
        case .mostlyCloudy, .cloudy:                                     return 3
        case .foggy:                                                     return 45
        case .haze:                                                      return 5
        case .drizzle:                                                   return 51
        case .rain:                                                      return 61
        case .heavyRain:                                                 return 65
        case .sunShowers:                                                return 80
        case .freezingDrizzle:                                           return 56
        case .freezingRain:                                              return 66
        case .sleet, .wintryMix:                                         return 77
        case .flurries, .snow, .sunFlurries:                             return 71
        case .heavySnow, .blowingSnow, .blizzard:                        return 75
        case .hail:                                                      return 96
        case .isolatedThunderstorms, .thunderstorms, .scatteredThunderstorms: return 95
        case .strongStorms, .tropicalStorm, .hurricane:                  return 99
        default:                                                         return 0
        }
    }
}
