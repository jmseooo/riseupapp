import UserNotifications
import Foundation

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let alarmID = "riseup.sunrise-alarm"

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func registerAlarmCategory() {
        let wakeAction = UNNotificationAction(
            identifier: "WAKE_ACTION",
            title: "일어나기",
            options: [.foreground]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "5분 더",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "SUNRISE_ALARM",
            actions: [wakeAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        center.setNotificationCategories([category])
    }

    func scheduleSunriseAlarm() async {
        let settings = AlarmSettings.shared
        guard settings.isEnabled else { await cancelSunriseAlarm(); return }

        guard let alarmDate = nextAlarmDate(settings: settings) else { return }

        await cancelSunriseAlarm()

        let content = UNMutableNotificationContent()
        content.title = "일어날 시간이에요 ☀️"
        content.body = "해가 떴습니다. 좋은 아침이에요!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.caf"))
        content.categoryIdentifier = "SUNRISE_ALARM"

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alarmDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: alarmID, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("[NotificationManager] schedule failed: \(error)")
        }
    }

    func cancelSunriseAlarm() async {
        center.removePendingNotificationRequests(withIdentifiers: [alarmID])
    }

    func pendingSunriseAlarm() async -> UNNotificationRequest? {
        await center.pendingNotificationRequests().first { $0.identifier == alarmID }
    }

    private func nextAlarmDate(settings: AlarmSettings) -> Date? {
        let now = Date()
        let offset = Double(settings.offsetMinutes) * 60

        if let todaySunrise = SunriseService.sunriseTime(latitude: settings.latitude, longitude: settings.longitude, date: now) {
            let alarm = todaySunrise.addingTimeInterval(offset)
            if alarm > now.addingTimeInterval(60) { return alarm }
        }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        return SunriseService.sunriseTime(latitude: settings.latitude, longitude: settings.longitude, date: tomorrow)
            .map { $0.addingTimeInterval(offset) }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        switch response.actionIdentifier {
        case "WAKE_ACTION", UNNotificationDefaultActionIdentifier:
            await MainActor.run {
                AlarmSettings.shared.recordWake()
                AlarmSettings.shared.pendingWakeUp = true
            }
        case "SNOOZE_ACTION":
            await scheduleSnooze(at: Date().addingTimeInterval(5 * 60))
        default:
            break
        }
        // Reschedule for next day only if repeat is enabled
        if AlarmSettings.shared.repeatEnabled {
            await scheduleSunriseAlarm()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    private func scheduleSnooze(at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "일어날 시간이에요 ☀️"
        content.body = "5분이 지났어요. 일어나세요!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.caf"))
        content.categoryIdentifier = "SUNRISE_ALARM"

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "riseup.snooze", content: content, trigger: trigger)
        try? await center.add(request)
    }
}
