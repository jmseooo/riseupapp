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
        static let wakeHistory = "wake_history"
        static let repeatEnabled = "alarm_repeat_enabled"
    }

    // Seoul fallback coordinates
    private static let fallbackLatitude = 37.5665
    private static let fallbackLongitude = 126.9780

    var pendingWakeUp: Bool = false
    var wakeHistory: [Date] {
        didSet {
            UserDefaults.standard.set(wakeHistory.map(\.timeIntervalSince1970), forKey: Keys.wakeHistory)
        }
    }

    var isEnabled: Bool { didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) } }
    var repeatEnabled: Bool { didSet { UserDefaults.standard.set(repeatEnabled, forKey: Keys.repeatEnabled) } }
    var offsetMinutes: Int { didSet { UserDefaults.standard.set(offsetMinutes, forKey: Keys.offsetMinutes) } }
    var latitude: Double { didSet { UserDefaults.standard.set(latitude, forKey: Keys.latitude) } }
    var longitude: Double { didSet { UserDefaults.standard.set(longitude, forKey: Keys.longitude) } }
    var hasCompletedOnboarding: Bool { didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) } }
    var locationPermissionDenied: Bool { didSet { UserDefaults.standard.set(locationPermissionDenied, forKey: Keys.locationPermissionDenied) } }

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Keys.isEnabled)
        repeatEnabled = UserDefaults.standard.object(forKey: Keys.repeatEnabled) as? Bool ?? true
        offsetMinutes = UserDefaults.standard.integer(forKey: Keys.offsetMinutes)
        let intervals = UserDefaults.standard.array(forKey: Keys.wakeHistory) as? [Double] ?? []
        wakeHistory = intervals.map { Date(timeIntervalSince1970: $0) }
        let storedLat = UserDefaults.standard.double(forKey: Keys.latitude)
        let storedLon = UserDefaults.standard.double(forKey: Keys.longitude)
        latitude = storedLat == 0 ? Self.fallbackLatitude : storedLat
        longitude = storedLon == 0 ? Self.fallbackLongitude : storedLon
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        locationPermissionDenied = UserDefaults.standard.bool(forKey: Keys.locationPermissionDenied)
    }

    // API 응답의 utc_offset_seconds 우선 사용, 없으면 경도 기반 근사값
    var locationTimezone: TimeZone {
        if let offset = WeatherService.shared.utcOffsetSeconds {
            return TimeZone(secondsFromGMT: offset) ?? .current
        }
        let offsetHours = Int(round(longitude / 15.0))
        return TimeZone(secondsFromGMT: offsetHours * 3600) ?? .current
    }

    var todaySunriseTime: Date? {
        if let s = WeatherService.shared.sunriseToday { return s }
        let now = Date()
        guard let y = localYear(from: now), let m = localMonth(from: now), let d = localDay(from: now) else { return nil }
        return SunriseService.sunriseTime(latitude: latitude, longitude: longitude, date: utcNoon(year: y, month: m, day: d))
    }

    // WeatherKit 우선, 없으면 NOAA 계산 fallback
    var nextSunriseTime: Date? {
        let now = Date()
        let svc = WeatherService.shared
        if let s = svc.sunriseToday, s > now { return s }
        if let s = svc.sunriseTomorrow { return s }

        guard let y = localYear(from: now), let m = localMonth(from: now), let d = localDay(from: now) else { return nil }
        let todayNoon = utcNoon(year: y, month: m, day: d)
        if let s = SunriseService.sunriseTime(latitude: latitude, longitude: longitude, date: todayNoon), s > now { return s }
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let tomorrowNoon = utcCal.date(byAdding: .day, value: 1, to: todayNoon)!
        return SunriseService.sunriseTime(latitude: latitude, longitude: longitude, date: tomorrowNoon)
    }

    var nextAlarmTime: Date? {
        guard let sunrise = nextSunriseTime else { return nil }
        let alarm = sunrise.addingTimeInterval(Double(offsetMinutes) * 60)
        return alarm > Date() ? alarm : nil
    }

    // MARK: - Wake history helpers

    func recordWake(on date: Date = Date()) {
        guard !wakeHistory.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) else { return }
        wakeHistory.append(date)
    }

    func wokeUp(on date: Date) -> Bool {
        wakeHistory.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }

    // MARK: - Helpers

    private func localYear(from date: Date) -> Int? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = locationTimezone
        return cal.component(.year, from: date)
    }
    private func localMonth(from date: Date) -> Int? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = locationTimezone
        return cal.component(.month, from: date)
    }
    private func localDay(from date: Date) -> Int? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = locationTimezone
        return cal.component(.day, from: date)
    }

    // 해당 날짜의 UTC 정오 — SunriseService(UTC 기준)에 넘기면 올바른 날의 일출을 계산
    private func utcNoon(year: Int, month: Int, day: Int) -> Date {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = 12; comps.minute = 0; comps.second = 0
        return utcCal.date(from: comps) ?? Date()
    }
}
