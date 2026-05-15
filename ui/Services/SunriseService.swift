import Foundation

// NOAA Solar Calculator — replaces Solar Swift Package (github.com/ceeK/Solar)
// Accuracy: ±1 min for latitudes 65°S – 65°N
struct SunriseService {

    static func sunriseTime(latitude: Double, longitude: Double, date: Date = Date()) -> Date? {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let comps = utcCal.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return nil }

        let jd = julianDay(year: y, month: m, day: d)
        let t = (jd - 2451545.0) / 36525.0

        // Geometric mean longitude (°)
        let L0 = mod360(280.46646 + t * (36000.76983 + t * 0.0003032))
        // Geometric mean anomaly (°)
        let M = mod360(357.52911 + t * (35999.05029 - t * 0.0001537))
        let Mrad = toRad(M)
        // Orbit eccentricity
        let e = 0.016708634 - t * (0.000042037 + t * 0.0000001267)
        // Equation of center
        let C = sin(Mrad) * (1.914602 - t * (0.004817 + t * 0.000014))
                + sin(2 * Mrad) * (0.019993 - t * 0.000101)
                + sin(3 * Mrad) * 0.000289
        // Sun's true longitude, apparent longitude
        let sunLon = L0 + C
        let omega = 125.04 - 1934.136 * t
        let lambda = sunLon - 0.00569 - 0.00478 * sin(toRad(omega))
        // Obliquity (°)
        let epsilon0 = 23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
        let epsilon = epsilon0 + 0.00256 * cos(toRad(omega))
        // Declination
        let delta = asin(sin(toRad(epsilon)) * sin(toRad(lambda)))
        // Equation of time (minutes)
        let y2 = pow(tan(toRad(epsilon / 2)), 2)
        let eot = toDeg(
            y2 * sin(toRad(2 * L0))
            - 2 * e * sin(Mrad)
            + 4 * e * y2 * sin(Mrad) * cos(toRad(2 * L0))
            - 0.5 * y2 * y2 * sin(toRad(4 * L0))
            - 1.25 * e * e * sin(toRad(2 * M))
        ) * 4
        // Solar noon (minutes from midnight UTC)
        let solarNoon = 720.0 - 4.0 * longitude - eot
        // Hour angle at sunrise (zenith = 90.833° accounts for refraction + solar disc)
        let cosHA = cos(toRad(90.833)) / (cos(toRad(latitude)) * cos(delta))
                    - tan(toRad(latitude)) * tan(delta)
        guard cosHA >= -1, cosHA <= 1 else { return nil } // polar day/night
        let ha = toDeg(acos(cosHA))
        // Sunrise (minutes from midnight UTC)
        let sunriseMinutes = solarNoon - ha * 4
        // Build Date
        let startOfDayUTC = utcCal.startOfDay(for: date)
        return startOfDayUTC.addingTimeInterval(sunriseMinutes * 60)
    }

    private static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = Double(y / 100)
        let b = 2.0 - a + Double(Int(a / 4))
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + Double(day) + b - 1524.5
    }

    private static func toRad(_ d: Double) -> Double { d * .pi / 180 }
    private static func toDeg(_ r: Double) -> Double { r * 180 / .pi }
    private static func mod360(_ v: Double) -> Double { v.truncatingRemainder(dividingBy: 360) }
}
