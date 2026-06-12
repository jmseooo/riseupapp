import SwiftUI

struct ContentView: View {
    @Environment(AlarmSettings.self) private var settings

    var body: some View {
        @Bindable var s = settings
        if settings.hasCompletedOnboarding {
            HomeView()
                .fullScreenCover(isPresented: $s.pendingWakeUp) {
                    WakeUpView { s.pendingWakeUp = false }
                        .environment(settings)
                }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AlarmSettings.shared)
}
