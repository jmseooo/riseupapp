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
    var isLoading = false
    var lastError: String?

    private init() {}

    func fetch(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude",  value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current",   value: "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,cloud_cover"),
            .init(name: "timezone",  value: "auto")
        ]

        guard let url = components.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let c = response.current
            current = WeatherData(
                temperature: c.temperature2m,
                weatherCode: c.weatherCode,
                windSpeed: c.windSpeed10m,
                humidity: c.relativeHumidity2m,
                cloudCover: c.cloudCover
            )
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            print("[WeatherService] fetch error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Decodable

private struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather
}

private struct CurrentWeather: Decodable {
    let temperature2m: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let relativeHumidity2m: Int
    let cloudCover: Int

    enum CodingKeys: String, CodingKey {
        case temperature2m     = "temperature_2m"
        case weatherCode       = "weather_code"
        case windSpeed10m      = "wind_speed_10m"
        case relativeHumidity2m = "relative_humidity_2m"
        case cloudCover        = "cloud_cover"
    }
}
