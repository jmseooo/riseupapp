import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @State private var page = 0
    @State private var locationManager = LocationManager.shared
    @Environment(AlarmSettings.self) private var settings

    var body: some View {
        TabView(selection: $page) {
            SplashSlide()
                .tag(0)
            OnboardingLocationSlide(
                locationManager: locationManager,
                onTap: {
                    if locationManager.authorizationStatus == .notDetermined {
                        locationManager.requestPermission()
                    } else {
                        settings.hasCompletedOnboarding = true
                    }
                },
                onComplete: { settings.hasCompletedOnboarding = true }
            )
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

// MARK: - Slide 1: Splash

private struct SplashSlide: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Warm sunrise gradient as background
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
        .onTapGesture {}  // absorbed so TabView swipe still works
    }
}

// MARK: - Slide 2: Location Permission

private struct OnboardingLocationSlide: View {
    let locationManager: LocationManager
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var requested = false

    var body: some View {
        ZStack {
            // Semi-frosted warm background
            WeatherBackground(condition: .sunrise)
            Color.white.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                Text("permission?")
                    .font(.pretendard(30, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.top, 98)

                // Permission card (iOS-style dialog simulation)
                permissionCard
                    .padding(.horizontal, 60)
                    .padding(.top, 30)

                Spacer()

                // Start button
                Button(action: handleButton) {
                    Text(requested ? "시작하기" : "위치 허용하기")
                        .font(.pretendard(24, weight: .semibold))
                        .foregroundStyle(requested ? Color.rTextDisabled : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.btnH)
                        .background(requested ? Color.rSurfaceInput : Color.rGreenBright)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 27)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .onChange(of: locationManager.authorizationStatus) { _, status in
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onComplete() }
            case .denied, .restricted:
                requested = true
            default: break
            }
        }
    }

    private var permissionCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Allow \u{201C}RiseUp\u{201D} to use\nyour location?")
                    .font(.system(size: 17, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
                Text("일출 시간은 위치마다 달라요. 위치 정보는 기기에만 저장됩니다.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)

            Divider()

            Group {
                Text("Allow Once")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                Divider()
                Text("Allow While Using the App")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                Divider()
                Text("Don't Allow")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.accentColor)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func handleButton() {
        if requested {
            onComplete()
        } else {
            requested = true
            onTap()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AlarmSettings.shared)
}
