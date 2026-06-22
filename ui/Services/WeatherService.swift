import Foundation
import CoreLocation

struct WeatherData {
    let temperature: Double  // °C
    let weatherCode: Int     // WMO
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

    private init() {}

    func fetch(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude",  value: "\(latitude)"),
            .init(name: "longitude", value: "\(longitude)"),
            .init(name: "current",   value: "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,cloud_cover"),
            .init(name: "daily",     value: "sunrise,sunset"),
            .init(name: "timezone",  value: "auto"),
            .init(name: "forecast_days", value: "2")
        ]

        do {
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            let c = response.current
            current = WeatherData(
                temperature: c.temperature2m,
                weatherCode: c.weatherCode,
                windSpeed:   c.windSpeed10m,
                humidity:    Int(c.relativeHumidity2m.rounded()),
                cloudCover:  Int(c.cloudCover.rounded())
            )

            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
            fmt.locale = Locale(identifier: "en_US_POSIX")

            sunriseToday    = response.daily.sunrise.first.flatMap { fmt.date(from: $0) }
            sunriseTomorrow = response.daily.sunrise.dropFirst().first.flatMap { fmt.date(from: $0) }

            utcOffsetSeconds = TimeZone.current.secondsFromGMT()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            print("[WeatherService] fetch error: \(error)")
        }
    }
}

// MARK: - Open-Meteo response models

private struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather
    let daily: DailyWeather
}

private struct CurrentWeather: Decodable {
    let temperature2m: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let relativeHumidity2m: Double
    let cloudCover: Double

    enum CodingKeys: String, CodingKey {
        case temperature2m        = "temperature_2m"
        case weatherCode          = "weather_code"
        case windSpeed10m         = "wind_speed_10m"
        case relativeHumidity2m   = "relative_humidity_2m"
        case cloudCover           = "cloud_cover"
    }
}

private struct DailyWeather: Decodable {
    let sunrise: [String]
    let sunset:  [String]
}
