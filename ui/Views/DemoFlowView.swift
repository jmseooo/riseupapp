// DemoFlowView.swift
// 프레젠테이션 전용 — 앱 전체 플로우 시연용 임시 파일
// 프로덕션 코드와 무관. 기존 코드에 영향 없음.

import SwiftUI

// 데모 전용 고정 배경값 — 날씨 fetch 없이 항상 동일한 색상 유지
private let demoWeather = WeatherData(temperature: 22, weatherCode: 0, windSpeed: 5, humidity: 40, cloudCover: 10)
private let demoHour = 10

// MARK: - Flow step

private enum DemoStep {
    case onboarding, main, wakeup
}

// MARK: - Root

struct DemoFlowView: View {
    @State private var step: DemoStep = .onboarding

    var body: some View {
        ZStack {
            switch step {
            case .onboarding:
                DemoOnboarding { withAnimation(.easeInOut(duration: 0.6)) { step = .main } }
                    .transition(.opacity)
            case .main:
                DemoMain { withAnimation(.easeInOut(duration: 0.6)) { step = .wakeup } }
                    .transition(.opacity)
            case .wakeup:
                WakeUpView { withAnimation(.easeInOut(duration: 0.6)) { step = .onboarding } }
                    .environment(AlarmSettings.shared)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 1. Onboarding (빈 뷰)

private struct DemoOnboarding: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 다음 버튼
            VStack {
                Spacer()
                DemoNextButton(label: "메인으로 →", action: onNext)
                    .padding(.bottom, 56)
            }
        }
    }
}

// MARK: - 2. Main

private struct DemoMain: View {
    let onAlarm: () -> Void

    @Environment(AlarmSettings.self) private var settings
    @State private var alarmOn = false
    @State private var showAppSettings = false

    @State private var typingText: String = ""
    @State private var typingTask: Task<Void, Never>? = nil
    @State private var descVisible: Bool = false
    private let alarmDesc = "The alarm rings at sunrise every day. Check tomorrow's sunrise time above. You can adjust the alarm time\nby pinching the screen."

    var body: some View {
        NavigationStack {
        ZStack(alignment: .bottom) {
            WeatherThemeBackground(weather: demoWeather, hour: demoHour)

            VStack(spacing: 0) {
                // 날씨 row
                HStack(alignment: .center) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(Int(demoWeather.temperature.rounded()))")
                            .font(.rajdhani(18))
                            .foregroundStyle(Color.rTextPrimary)
                        Text("°")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(Color.rTextPrimary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.rTextPrimary)
                        Text("Good Morning")
                            .font(.prompt(18, weight: .semiBold))
                            .foregroundStyle(Color.rTextPrimary)
                    }
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 60)

                Spacer()

                // 일출 시간
                VStack(alignment: .leading, spacing: 0) {
                    GlassTimeTextA(timeString: timeString)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.hPad)

                // 카운트다운 + chevron
                HStack {
                    Text(countdownText)
                        .font(.prompt(18))
                        .foregroundStyle(Color.rBlackWarm)
                    Spacer()
                    Button {
                        if descVisible {
                            typingTask?.cancel()
                            typingText = ""
                            withAnimation(.easeOut(duration: 0.3)) { descVisible = false }
                        } else {
                            startTyping()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.rTextPrimary)
                    }
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 2)

                // 알람 설명 텍스트 (타이핑 애니메이션)
                if !alarmOn && descVisible {
                    ZStack(alignment: .topLeading) {
                        Text(alarmDesc).opacity(0)
                        Text(typingText)
                    }
                    .font(.prompt(13))
                    .foregroundStyle(Color.rOrange)
                    .kerning(-0.13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.hPad)
                    .padding(.top, 10)
                    .transition(.opacity)
                }

                Color.clear.frame(height: 116)
                Spacer()

                // 알람 카드 + 하단 nav 공간 확보
                Color.clear.frame(height: 140)
            }

            // 알람 카드 + 하단 nav
            VStack(spacing: 0) {
                // 알람 카드
                HStack {
                    Text("alarm")
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.rTextPrimary)
                        .kerning(-0.45)
                    Spacer()
                    Toggle("", isOn: $alarmOn)
                        .labelsHidden()
                        .tint(Color.rGreenAccent)
                        .onChange(of: alarmOn) { _, enabled in
                            if !enabled { startTyping() } else {
                                typingTask?.cancel()
                                typingText = ""
                                withAnimation(.easeOut(duration: 0.3)) { descVisible = false }
                            }
                        }
                }
                .padding(20)
                .background(Color.rSurfaceGlass)
                .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
                .cardShadow()
                .padding(.horizontal, DS.hPad)
                .padding(.bottom, 16)

                // 하단 nav
                HStack(spacing: 24) {
                    NavigationLink {
                        PersonalView().environment(settings)
                    } label: {
                        Image(systemName: "sun.min.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.rBlackWarm)
                    }
                    NavigationLink {
                        TodoView().environment(settings)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.rBlackWarm)
                    }
                    Button { showAppSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.rBlackWarm)
                    }
                }
                .padding(.horizontal, 30)
                .frame(height: DS.navH)
                .background(Color.rSurfaceFrost)
                .clipShape(Capsule())
                .cardShadow()
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAppSettings) { AppSettingsView() }
        } // NavigationStack
        .overlay(alignment: .bottom) {
            DemoNextButton(label: "알람 울림 →", action: onAlarm)
                .padding(.bottom, 140)
        }
        .onAppear {
            startTyping()
        }
    }

    private func startTyping() {
        typingTask?.cancel()
        typingText = ""
        withAnimation(.easeIn(duration: 0.25)) { descVisible = true }
        typingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            guard !Task.isCancelled else { return }
            for char in alarmDesc {
                try? await Task.sleep(nanoseconds: 22_000_000)
                guard !Task.isCancelled else { break }
                typingText.append(char)
            }
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) { descVisible = false }
        }
    }

    private var timeString: String { "5:10" }

    private var countdownText: String {
        guard let alarm = AlarmSettings.shared.nextAlarmTime else { return "-- h -- m" }
        let diff = alarm.timeIntervalSince(Date())
        guard diff > 0 else { return "곧 일출" }
        let h = Int(diff) / 3600
        let m = Int(diff) % 3600 / 60
        if h > 0 { return "The sun will rise in \(h)h \(m)m." }
        return "The sun will rise in \(m)m."
    }
}

// MARK: - Demo 전용 네비게이션 버튼

private struct DemoNextButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
        }
    }
}

// MARK: - Preview

#Preview {
    DemoFlowView()
        .environment(AlarmSettings.shared)
}
