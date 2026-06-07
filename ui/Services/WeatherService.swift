import Foundation

struct WeatherData {
    let temperature: Double  // °C
    let weatherCode: Int     // WMO code
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

        let urlStr = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,cloud_cover"
            + "&daily=sunrise,sunset"
            + "&timezone=auto&forecast_days=2"

        guard let url = URL(string: urlStr) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let c = resp.current

            current = WeatherData(
                temperature: c.temperature_2m,
                weatherCode: c.weather_code,
                windSpeed: c.wind_speed_10m,
                humidity: c.relative_humidity_2m,
                cloudCover: c.cloud_cover
            )

            utcOffsetSeconds = resp.utc_offset_seconds

            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
            fmt.timeZone = TimeZone(secondsFromGMT: resp.utc_offset_seconds ?? 0)

            if let sunrises = resp.daily?.sunrise {
                if sunrises.count >= 1 { sunriseToday    = fmt.date(from: sunrises[0]) }
                if sunrises.count >= 2 { sunriseTomorrow = fmt.date(from: sunrises[1]) }
            }

            lastError = nil
            print("[WeatherService] temp: \(c.temperature_2m)°C, code: \(c.weather_code)")
        } catch {
            lastError = error.localizedDescription
            print("[WeatherService] fetch error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Open-Meteo response models

private struct OpenMeteoResponse: Codable {
    let current: Current
    let daily: Daily?
    let utc_offset_seconds: Int?

    struct Current: Codable {
        let temperature_2m: Double
        let relative_humidity_2m: Int
        let weather_code: Int
        let wind_speed_10m: Double
        let cloud_cover: Int
    }

    struct Daily: Codable {
        let sunrise: [String]?
    }
}
