import BackgroundTasks
import Foundation

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let taskIdentifier = "terry.ui.sunrise-refresh"

    func registerTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Aim for ~00:05 so the next day's alarm is ready before sunrise
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(6 * 3600)
        request.earliestBeginDate = nextMidnight

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[BackgroundTaskManager] submit failed: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh before doing work
        scheduleNextRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            LocationManager.shared.updateLocation()
            await NotificationManager.shared.scheduleSunriseAlarm()
            task.setTaskCompleted(success: true)
        }
    }
}
