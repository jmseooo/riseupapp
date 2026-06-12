import SwiftUI
import CoreLocation
import MapKit
import UserNotifications

struct OnboardingView: View {
    var alwaysShowDialog: Bool = false
    private let locationManager = LocationManager.shared

    private enum Step {
        case welcome, welcome2, welcome3, intro, location, notification
    }

    @State private var step: Step = .intro
    @State private var typingText = ""
    @State private var typingTask: Task<Void, Never>? = nil
    @State private var showDialog = false
    @State private var welcomeTextVisible = false
    @State private var welcome2TextVisible = false
    @State private var welcome3TextVisible = false
    @State private var notificationDialogTriggered = false

    private let subtitle = "Embracing a natural circadian rhythm guided by\nthe sun's movement."

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                welcomeScreen.transition(.opacity)
            case .welcome2:
                welcomeScreen2.transition(.opacity)
            case .welcome3:
                welcomeScreen3.transition(.opacity)
            case .intro:
                introScreen.transition(.opacity)
            case .location:
                locationScreen.transition(.opacity)
            case .notification:
                notificationScreen.transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: step)
    }

    // MARK: - Step 0: Welcome

    private var welcomeScreen: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.831, green: 0.899, blue: 1.0).ignoresSafeArea()

                // White arc (large circle stroke: center 326,731 radius 377 in 390×844 space)
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: 0, y: h * 0.642))
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h * 0.426),
                        control: CGPoint(x: w * 0.5, y: h * 0.360)
                    )
                }
                .stroke(Color.white, lineWidth: 2)

                // Orb image (center at ~45% of screen height)
                Image("IntroOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.9)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.455)

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 89)

                    Text("SUNERS is an alarm app\nthat wakes you at\nsunrise.")
                        .font(.pretendard(18, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.leading, 24)
                        .opacity(welcomeTextVisible ? 1 : 0)
                        .offset(y: welcomeTextVisible ? 0 : 28)
                        .animation(.easeOut(duration: 0.55).delay(0.15), value: welcomeTextVisible)

                    Spacer()

                    // Pagination dots
                    HStack(spacing: 6) {
                        Spacer()
                        Circle()
                            .fill(Color(red: 1, green: 0.479, blue: 0.238))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color(red: 0.733, green: 0.733, blue: 0.733))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color(red: 0.733, green: 0.733, blue: 0.733))
                            .frame(width: 10, height: 10)
                        Spacer()
                    }
                    .padding(.bottom, 20)

                    // Next button
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) { step = .welcome2 }
                    } label: {
                        Text("Next")
                            .font(.pretendard(17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 66)
                            .background(Color(red: 1, green: 0.479, blue: 0.238))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 27)
                    .padding(.bottom, 56)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            welcomeTextVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                welcomeTextVisible = true
            }
        }
        .onDisappear { welcomeTextVisible = false }
    }

    // MARK: - Step 0b: Welcome page 2

    private var welcomeScreen2: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 1, green: 0.907, blue: 0.878), location: 0),
                        .init(color: Color(red: 0.930, green: 1, blue: 0.581), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Dots image (6 dots hexagon, centered at ~50% of screen)
                Image("DotsOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.72)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.50)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 89)

                    Text("Experience a\nrenewed sense of vitality.")
                        .font(.pretendard(18, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.leading, 24)
                        .opacity(welcome2TextVisible ? 1 : 0)
                        .offset(y: welcome2TextVisible ? 0 : 28)
                        .animation(.easeOut(duration: 0.55).delay(0.15), value: welcome2TextVisible)

                    Spacer()

                    // Pagination dots (middle active = page 2)
                    HStack(spacing: 6) {
                        Spacer()
                        Circle()
                            .fill(Color(red: 0.733, green: 0.733, blue: 0.733))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color(red: 1, green: 0.479, blue: 0.238))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color(red: 0.733, green: 0.733, blue: 0.733))
                            .frame(width: 10, height: 10)
                        Spacer()
                    }
                    .padding(.bottom, 20)

                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) { step = .welcome3 }
                    } label: {
                        Text("Next")
                            .font(.pretendard(17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 66)
                            .background(Color(red: 1, green: 0.479, blue: 0.238))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 27)
                    .padding(.bottom, 56)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            welcome2TextVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                welcome2TextVisible = true
            }
        }
        .onDisappear { welcome2TextVisible = false }
    }

    // MARK: - Step 0c: Welcome page 3

    private var welcomeScreen3: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.831, green: 0.899, blue: 1.0).ignoresSafeArea()

                // Sun orb card image (299×364 in 390×844 space)
                Image("SunOrbCard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * (299.0 / 390.0))
                    .position(x: geo.size.width / 2, y: geo.size.height * (422.0 / 844.0))

                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 89)

                    Text("Begin your day with SUNNERS.")
                        .font(.pretendard(18, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.leading, 24)
                        .opacity(welcome3TextVisible ? 1 : 0)
                        .offset(y: welcome3TextVisible ? 0 : 28)
                        .animation(.easeOut(duration: 0.55).delay(0.15), value: welcome3TextVisible)

                    Spacer()

                    // Pagination dots (last active = page 3)
                    HStack(spacing: 6) {
                        Spacer()
                        Circle()
                            .fill(Color(red: 0.733, green: 0.733, blue: 0.733))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color(red: 0.733, green: 0.733, blue: 0.733))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color(red: 1, green: 0.479, blue: 0.238))
                            .frame(width: 10, height: 10)
                        Spacer()
                    }
                    .padding(.bottom, 20)

                    Button {
                        if !alwaysShowDialog {
                            AlarmSettings.shared.hasCompletedOnboarding = true
                        }
                    } label: {
                        Text("Start")
                            .font(.pretendard(16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 66)
                            .background(Color(red: 1, green: 0.479, blue: 0.238))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 27)
                    .padding(.bottom, 56)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            welcome3TextVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                welcome3TextVisible = true
            }
        }
        .onDisappear { welcome3TextVisible = false }
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

            VStack {
                Spacer()
                skipButton {
                    showDialog = false
                    withAnimation(.easeInOut(duration: 0.5)) { step = .notification }
                }
                .padding(.bottom, 72)
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showDialog)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if alwaysShowDialog || locationManager.authorizationStatus == .notDetermined {
                    showDialog = true
                }
                // 이미 결정된 권한이면 다이얼로그 없이 다음 버튼만 표시
            }
        }
    }

    // MARK: - Step 3: Notification

    private var notificationScreen: some View {
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
                notificationDialog
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            VStack {
                Spacer()
                skipButton {
                    showDialog = false
                    withAnimation(.easeInOut(duration: 0.5)) { step = .welcome }
                }
                .padding(.bottom, 72)
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showDialog)
        .onAppear {
            guard !notificationDialogTriggered else { return }
            notificationDialogTriggered = true
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if alwaysShowDialog || settings.authorizationStatus == .notDetermined {
                        showDialog = true
                    }
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
                    if !alwaysShowDialog { locationManager.requestPermission() }
                    withAnimation(.easeInOut(duration: 0.5)) { step = .notification }
                }
                Divider()
                dialogButton("Allow While Using the App") {
                    showDialog = false
                    if !alwaysShowDialog { locationManager.requestPermission() }
                    withAnimation(.easeInOut(duration: 0.5)) { step = .notification }
                }
                Divider()
                dialogButton("Don't Allow") {
                    showDialog = false
                }
            }
        }
        .frame(width: 270)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Notification dialog

    private var notificationDialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Allow \u{201C}SUNERS\u{201D} to send\nyou notifications?")
                    .font(.system(size: 17, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                Text("Notifications are used to ring your alarm\nat the exact moment the sun rises.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
            }
            .padding(16)

            Group {
                Divider()
                dialogButton("Don't Allow") {
                    showDialog = false
                }
                Divider()
                dialogButton("Allow") {
                    showDialog = false
                    if !alwaysShowDialog {
                        Task { _ = await NotificationManager.shared.requestAuthorization() }
                    }
                    withAnimation(.easeInOut(duration: 0.5)) { step = .welcome }
                }
            }
        }
        .frame(width: 270)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("다음 →")
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
        }
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
