import Foundation

@Observable
final class AlarmSettings {
    static let shared = AlarmSettings()

    private enum Keys {
        static let isEnabled = "alarm_enabled"
        static let offsetMinutes = "alarm_offset_minutes"
        static let latitude = "last_latitude"
        static let longitude = "last_longitude"
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let locationPermissionDenied = "location_permission_denied"
    }

    // Seoul fallback coordinates
    private static let fallbackLatitude = 37.5665
    private static let fallbackLongitude = 126.9780

    var isEnabled: Bool { didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) } }
    var offsetMinutes: Int { didSet { UserDefaults.standard.set(offsetMinutes, forKey: Keys.offsetMinutes) } }
    var latitude: Double { didSet { UserDefaults.standard.set(latitude, forKey: Keys.latitude) } }
    var longitude: Double { didSet { UserDefaults.standard.set(longitude, forKey: Keys.longitude) } }
    var hasCompletedOnboarding: Bool { didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) } }
    var locationPermissionDenied: Bool { didSet { UserDefaults.standard.set(locationPermissionDenied, forKey: Keys.locationPermissionDenied) } }

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Keys.isEnabled)
        offsetMinutes = UserDefaults.standard.integer(forKey: Keys.offsetMinutes)
        let storedLat = UserDefaults.standard.double(forKey: Keys.latitude)
        let storedLon = UserDefaults.standard.double(forKey: Keys.longitude)
        latitude = storedLat == 0 ? Self.fallbackLatitude : storedLat
        longitude = storedLon == 0 ? Self.fallbackLongitude : storedLon
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        locationPermissionDenied = UserDefaults.standard.bool(forKey: Keys.locationPermissionDenied)
    }

    var todaySunriseTime: Date? {
        SunriseService.sunriseTime(latitude: latitude, longitude: longitude, date: Date())
    }

    var nextAlarmTime: Date? {
        let now = Date()
        if let todaySunrise = SunriseService.sunriseTime(latitude: latitude, longitude: longitude, date: now) {
            let alarmTime = todaySunrise.addingTimeInterval(Double(offsetMinutes) * 60)
            if alarmTime > now { return alarmTime }
        }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        guard let tomorrowSunrise = SunriseService.sunriseTime(latitude: latitude, longitude: longitude, date: tomorrow) else { return nil }
        return tomorrowSunrise.addingTimeInterval(Double(offsetMinutes) * 60)
    }
}
