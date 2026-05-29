import SwiftUI

struct ContentView: View {
    @Environment(AlarmSettings.self) private var settings
    @State private var isReady = false

    var body: some View {
        @Bindable var s = settings
        if !isReady {
            SplashView()
                .task { await prepareApp() }
        } else if settings.hasCompletedOnboarding {
            HomeView()
                .fullScreenCover(isPresented: $s.pendingWakeUp) {
                    WakeUpView { s.pendingWakeUp = false }
                        .environment(settings)
                }
        } else {
            OnboardingView()
        }
    }

    private func prepareApp() async {
        LocationManager.shared.updateLocation()

        // 백그라운드에서 날씨 fetch 시작 (결과를 기다리지 않음)
        Task {
            if WeatherService.shared.current == nil {
                await WeatherService.shared.fetch(
                    latitude: settings.latitude,
                    longitude: settings.longitude
                )
            }
        }

        // 2초 후 날씨 로딩 완료 여부와 관계없이 이동
        try? await Task.sleep(for: .seconds(2))
        isReady = true
    }
}

#Preview {
    ContentView()
        .environment(AlarmSettings.shared)
}
