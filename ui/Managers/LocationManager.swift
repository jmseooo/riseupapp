import CoreLocation
import Foundation

@Observable
final class LocationManager: NSObject {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            AlarmSettings.shared.locationPermissionDenied = true
        @unknown default:
            break
        }
    }

    func updateLocation() {
        guard manager.authorizationStatus == .authorizedAlways
                || manager.authorizationStatus == .authorizedWhenInUse else { return }
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        AlarmSettings.shared.latitude = lat
        AlarmSettings.shared.longitude = lon
        AlarmSettings.shared.locationPermissionDenied = false

        Task {
            await WeatherService.shared.fetch(latitude: lat, longitude: lon)
            if AlarmSettings.shared.isEnabled {
                await NotificationManager.shared.scheduleSunriseAlarm()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Cached coordinates in AlarmSettings are used as fallback
        print("[LocationManager] error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            AlarmSettings.shared.locationPermissionDenied = false
            manager.requestLocation()
        case .denied, .restricted:
            AlarmSettings.shared.locationPermissionDenied = true
        default:
            break
        }
    }
}
