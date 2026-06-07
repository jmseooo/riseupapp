import SwiftUI

struct ContentView: View {
    @Environment(AlarmSettings.self) private var settings
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false

    var body: some View {
        @Bindable var s = settings
        if hasCompletedOnboarding {
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
