import SwiftUI

struct ContentView: View {
    @Environment(AlarmSettings.self) private var settings

    var body: some View {
        if settings.hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AlarmSettings.shared)
}
