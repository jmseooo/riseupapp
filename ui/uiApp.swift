import SwiftUI
import BackgroundTasks

@main
struct uiApp: App {

    private let settings = AlarmSettings.shared

    init() {
        BackgroundTaskManager.shared.registerTask()
        NotificationManager.shared.registerAlarmCategory()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .task {
                    guard settings.isEnabled else { return }
                    let pending = await NotificationManager.shared.pendingSunriseAlarm()
                    if pending == nil {
                        await NotificationManager.shared.scheduleSunriseAlarm()
                    }
                    BackgroundTaskManager.shared.scheduleNextRefresh()
                }
        }
    }
}
