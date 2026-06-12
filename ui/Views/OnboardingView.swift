import SwiftUI
import CoreLocation

struct OnboardingView: View {
    private let locationManager = LocationManager.shared

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            WeatherBackground(condition: .sunrise)

            VStack(alignment: .leading, spacing: 0) {
                Text("Hello.")
                    .font(.pretendard(30, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 30)
                    .padding(.top, 98)

                Spacer()

                Text("RiseUp")
                    .font(.pretendard(84, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 57)
                    .padding(.bottom, 122)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                } else {
                    requestNotificationThenFinish()
                }
            }
        }
        .onChange(of: locationManager.authorizationStatus) { (_, status: CLAuthorizationStatus) in
            if status != .notDetermined {
                requestNotificationThenFinish()
            }
        }
    }

    private func requestNotificationThenFinish() {
        Task { @MainActor in
            AlarmSettings.shared.hasCompletedOnboarding = true
            _ = await NotificationManager.shared.requestAuthorization()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AlarmSettings.shared)
}
