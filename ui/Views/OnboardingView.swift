import SwiftUI
import CoreLocation
import MapKit

struct OnboardingView: View {
    var alwaysShowDialog: Bool = false
    private let locationManager = LocationManager.shared

    private enum Step {
        case intro, location
    }

    @State private var step: Step = .intro
    @State private var typingText = ""
    @State private var typingTask: Task<Void, Never>? = nil
    @State private var showDialog = false

    private let subtitle = "Embracing a natural circadian rhythm guided by\nthe sun's movement."

    var body: some View {
        ZStack {
            switch step {
            case .intro:
                introScreen.transition(.opacity)
            case .location:
                locationScreen.transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: step)
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status != .notDetermined {
                showDialog = false
                AlarmSettings.shared.hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - Step 1: Intro

    private var introScreen: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 10) {
                Text("SUNERS")
                    .font(.pretendard(42, weight: .heavy))
                    .foregroundStyle(Color.rOrange)
                    .tracking(0.84)

                ZStack(alignment: .top) {
                    Text(subtitle).opacity(0)
                    Text(typingText)
                }
                .font(.pretendard(12))
                .foregroundStyle(Color.rOrange)
                .tracking(0.24)
                .multilineTextAlignment(.center)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            typingTask?.cancel()
            withAnimation(.easeInOut(duration: 0.5)) { step = .location }
        }
        .onAppear { startTyping() }
    }

    // MARK: - Step 2: Location

    private var locationScreen: some View {
        ZStack {
            Color.white

            GeometryReader { geo in
                Image("SunOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 2)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.81)
            }

            VStack(spacing: 0) {
                HStack {
                    Text("SUNERS")
                        .font(.pretendard(20, weight: .heavy))
                        .foregroundStyle(Color.rOrange)
                        .tracking(0.4)
                        .padding(.leading, 28)
                    Spacer()
                }
                .padding(.top, 89)
                Spacer()
            }

            if showDialog {
                Color.black.opacity(0.15).ignoresSafeArea()
                locationDialog
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showDialog)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                } else if alwaysShowDialog {
                    showDialog = true
                }
            }
        }
    }

    // MARK: - Location dialog

    private var locationDialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Allow \u{201C}SUNERS\u{201D} to use\nyour location?")
                    .font(.system(size: 17, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                Text("Your location is used to calculate\nthe exact sunrise time for where you are.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
            }
            .padding(16)

            Map()
                .frame(width: 270, height: 160)
                .disabled(true)

            Group {
                Divider()
                dialogButton("Allow Once") {
                    showDialog = false
                    AlarmSettings.shared.hasCompletedOnboarding = true
                }
                Divider()
                dialogButton("Allow While Using the App") {
                    showDialog = false
                    AlarmSettings.shared.hasCompletedOnboarding = true
                }
                Divider()
                dialogButton("Don't Allow") {
                    showDialog = false
                    AlarmSettings.shared.hasCompletedOnboarding = true
                }
            }
        }
        .frame(width: 270)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dialogButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Color(hex: "#007AFF"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }

    // MARK: - Typing animation

    private func startTyping() {
        typingTask?.cancel()
        typingText = ""
        typingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            for char in subtitle {
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: 30_000_000)
                typingText.append(char)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AlarmSettings.shared)
}
