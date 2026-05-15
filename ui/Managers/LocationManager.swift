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
        AlarmSettings.shared.latitude = location.coordinate.latitude
        AlarmSettings.shared.longitude = location.coordinate.longitude
        AlarmSettings.shared.locationPermissionDenied = false

        if AlarmSettings.shared.isEnabled {
            Task { await NotificationManager.shared.scheduleSunriseAlarm() }
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
