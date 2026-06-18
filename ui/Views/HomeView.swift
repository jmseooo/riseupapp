
import SwiftUI
import Combine
import WeatherKit

struct HomeView: View {
    @Environment(AlarmSettings.self) private var settings
    @State private var now = Date()
    private let weather = WeatherService.shared

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    @State private var showAppSettings = false
    @State private var isPinching: Bool = false
    @State private var isPinchExpanded: Bool = false
    @State private var wobble: CGFloat = 0
    @State private var floatY: CGFloat = 0
    @State private var pinchDotCount: Int = 0
    @State private var dragStartOffset: Int? = nil

    private let hapticSelection = UISelectionFeedbackGenerator()
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    @State private var lastHapticScale: CGFloat = 1.0

    @State private var typingText: String = ""
    @State private var typingTask: Task<Void, Never>? = nil
    @State private var descVisible: Bool = false
    private let alarmDesc = "The alarm rings at sunrise every day. Check tomorrow's sunrise time above. You can adjust the alarm time\nby pinching the screen."

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                WeatherThemeBackground(
                    weather: weather.current,
                    hour: Calendar.current.component(.hour, from: now)
                )

                VStack(spacing: 0) {
                    // ── Weather row ────────────────────────────────────────
                    if !isPinchExpanded {
                        HStack(alignment: .center, spacing: 0) {
                            temperatureView
                            Spacer()
                            weatherConditionView
                        }
                        .padding(.horizontal, DS.hPad)
                        .padding(.top, 60)
                        .transition(.opacity)
                    }


                    Spacer()

                    // ── Sunrise time ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        GlassTimeTextA(timeString: timeString)
                            .offset(x: wobble, y: floatY)
                            .scaleEffect(isPinchExpanded ? 1.5 : 1.0, anchor: .topLeading)
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPinchExpanded)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                                    floatY = 3.5
                                }
                            }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.hPad)
                    .offset(y: isPinchExpanded ? -25 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPinchExpanded)

                    // ── Countdown ──────────────────────────────────────────
                    if !isPinchExpanded, let cd = countdownText {
                        HStack {
                            Text(cd)
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
                                    .foregroundStyle(Color.rTextSub)
                            }
                        }
                        .padding(.horizontal, DS.hPad)
                        .padding(.top, 2)
                        .transition(.opacity)
                    }

                    // ── Alarm description ──────────────────────────────────
                    if !isPinchExpanded && descVisible {
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

                        weatherAttribution
                            .padding(.horizontal, DS.hPad)
                            .padding(.top, 6)
                            .transition(.opacity)
                    }

                    Color.clear.frame(height: 116)

                    Spacer()

                    // ── Debug info ────────────────────────────────────────
                    #if targetEnvironment(simulator)
                    if !isPinchExpanded {
                        Text(debugInfo)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.hPad)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }
                    #endif

                    // alarmCard + bottomNav 높이만큼 여백 확보
                    if !isPinchExpanded {
                        Color.clear.frame(height: 140)
                    }
                }

                // ── Alarm card + Bottom nav (고정 오버레이) ────────────────
                if !isPinchExpanded {
                    VStack(spacing: 0) {
                        alarmCard
                            .padding(.horizontal, DS.hPad)
                            .padding(.bottom, 16)
                        bottomNav
                            .padding(.bottom, 24)
                    }
                    .transition(.opacity)
                }


                // ── Pinch dots + drag to offset time (right side) ─────
                if pinchDotCount > 0 {
                    ZStack(alignment: .trailing) {
                        // 시각적 도트 (터치 비활성)
                        VStack(spacing: 30) {
                            Spacer().frame(height: 108)
                            ForEach(0..<pinchDotCount, id: \.self) { _ in
                                Circle()
                                    .fill(Color.rBlackWarm.opacity(0.45))
                                    .frame(width: 5, height: 5)
                            }
                            Spacer().frame(height: 192)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .padding(.trailing, 22)
                        .allowsHitTesting(false)

                        // 드래그 입력 영역 (도트 위 우측 스트립)
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: 60)
                            .padding(.top, 108)
                            .padding(.bottom, 192)
                            .gesture(
                                DragGesture(minimumDistance: 8)
                                    .onChanged { value in
                                        if dragStartOffset == nil {
                                            dragStartOffset = settings.offsetMinutes
                                        }
                                        // 40pt 드래그 = 10분
                                        let steps = Int(value.translation.height / 40)
                                        let newOffset = (dragStartOffset ?? 0) - steps * 10
                                        withAnimation(.easeOut(duration: 0.08)) {
                                            settings.offsetMinutes = newOffset
                                        }
                                    }
                                    .onEnded { _ in
                                        dragStartOffset = nil
                                    }
                            )
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
            .contentShape(Rectangle())
            .simultaneousGesture(
                MagnificationGesture(minimumScaleDelta: 0.01)
                    .onChanged { scale in
                        if !isPinching {
                            isPinching = true
                            lastHapticScale = scale
                            hapticSelection.prepare()
                            hapticImpact.prepare()
                            hapticSelection.selectionChanged()
                            withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true)) {
                                wobble = 3
                            }
                        } else if abs(scale - lastHapticScale) >= 0.04 {
                            hapticSelection.selectionChanged()
                            lastHapticScale = scale
                        }
                    }
                    .onEnded { _ in
                        isPinching = false
                        hapticImpact.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            wobble = 0
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPinchExpanded.toggle()
                        }
                        if isPinchExpanded {
                            pinchDotCount = 0
                            for i in 1...15 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                        pinchDotCount = i
                                    }
                                }
                            }
                        } else {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                pinchDotCount = 0
                            }
                        }
                    }
            )
            .overlay(alignment: .bottom) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        settings.offsetMinutes = 0
                    }
                } label: {
                    Text("reset")
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.btnH)
                        .background(Color.rBlackWarm)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, DS.hPad)
                .padding(.bottom, 48)
                .opacity(isPinchExpanded && settings.offsetMinutes != 0 ? 1 : 0)
                .allowsHitTesting(isPinchExpanded && settings.offsetMinutes != 0)
                .animation(.easeInOut(duration: 0.25), value: settings.offsetMinutes)
            }
            .onReceive(ticker) { now = $0 }
            .sheet(isPresented: $showAppSettings) {
                AppSettingsView()
            }
            .onAppear {
                if !settings.isEnabled { startTyping() }
            }
            .task {
                LocationManager.shared.updateLocation()
                await WeatherService.shared.fetch(latitude: settings.latitude, longitude: settings.longitude)
                guard settings.isEnabled else { return }
                let pending = await NotificationManager.shared.pendingSunriseAlarm()
                if pending == nil {
                    await NotificationManager.shared.scheduleSunriseAlarm()
                }
            }
        }
    }

    // MARK: - WeatherKit attribution

    private var weatherAttribution: some View {
        let w = WeatherService.shared
        let legalURL = w.attribution?.legalPageURL
            ?? URL(string: "https://weatherkit.apple.com/legal-attribution.html")!
        let markURL = w.attribution?.combinedMarkLightURL

        return HStack(spacing: 4) {
            Link(destination: legalURL) {
                HStack(spacing: 4) {
                    if let markURL {
                        AsyncImage(url: markURL) { img in
                            img.resizable().scaledToFit()
                        } placeholder: {
                            EmptyView()
                        }
                        .frame(height: 10)
                    } else {
                        Text("Weather")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - Sub-views

    private var temperatureView: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(weather.current.map { "\(Int($0.temperature.rounded()))" } ?? "--")
                .font(.rajdhani(18))
                .foregroundStyle(.white)
            Text("°")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
        }
    }

    private var weatherConditionView: some View {
        HStack(spacing: 6) {
            Image(systemName: weatherIcon)
                .font(.system(size: 22))
                .foregroundStyle(.white)
            Text(greeting)
                .font(.prompt(18, weight: .semiBold))
                .foregroundStyle(.white)
        }
    }

    private var alarmCard: some View {
        @Bindable var settings = settings
        return HStack {
            Text("alarm")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(Color.rTextPrimary)
                .kerning(-0.45)

            Spacer()

            Toggle("", isOn: $settings.isEnabled)
                .labelsHidden()
                .tint(Color.rGreenAccent)
                .onChange(of: settings.isEnabled) { _, enabled in
                    Task {
                        if enabled {
                            let granted = await NotificationManager.shared.requestAuthorization()
                            if granted {
                                await NotificationManager.shared.scheduleSunriseAlarm()
                                BackgroundTaskManager.shared.scheduleNextRefresh()
                            } else {
                                settings.isEnabled = false
                            }
                        } else {
                            await NotificationManager.shared.cancelSunriseAlarm()
                            startTyping()
                        }
                    }
                }
        }
        .padding(20)
        .background(Color.rSurfaceGlass)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .cardShadow()
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
            // 타이핑 완료 후 10초 뒤 자동 숨김
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) { descVisible = false }
        }
    }

    private var bottomNav: some View {
        HStack(spacing: 24) {
            NavigationLink {
                PersonalView()
                    .environment(settings)
            } label: {
                Image(systemName: "sun.min.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.rBlackWarm)
            }

            NavigationLink {
                TodoView()
                    .environment(settings)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.rBlackWarm)
            }

            Button {
                showAppSettings = true
            } label: {
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
    }

    // MARK: - Helpers

    private var debugInfo: String {
        let dayF = DateFormatter()
        dayF.dateFormat = "M/d (EEE)"
        dayF.timeZone = settings.locationTimezone
        let dateStr = dayF.string(from: now)

        let sunriseStr: String
        if let sunrise = settings.nextSunriseTime {
            let tf = DateFormatter()
            tf.dateFormat = "H:mm"
            tf.timeZone = settings.locationTimezone
            sunriseStr = tf.string(from: sunrise)
        } else {
            sunriseStr = "--:--"
        }

        let tempStr = weather.current.map { "\(Int($0.temperature.rounded()))°C" } ?? "--°C"
        let codeStr = weather.current.map { "WMO:\($0.weatherCode)" } ?? "WMO:--"
        let cloudStr = weather.current.map { "cloud:\($0.cloudCover)%" } ?? "cloud:--"
        let lat = String(format: "%.2f", settings.latitude)
        let lon = String(format: "%.2f", settings.longitude)
        let errStr = weather.lastError.map { "ERR:\($0)" } ?? ""
        return "일출 \(sunriseStr)  \(tempStr)  \(codeStr)  \(cloudStr)  \(dateStr)  (\(lat), \(lon))  \(errStr)"
    }

    private var timeString: String {
        guard let sunrise = settings.nextSunriseTime else { return "--:--" }
        let adjusted = sunrise.addingTimeInterval(Double(settings.offsetMinutes) * 60)
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        f.timeZone = settings.locationTimezone
        return f.string(from: adjusted)
    }

    private var dayLabel: String {
        guard let sunrise = settings.nextSunriseTime else { return "" }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = settings.locationTimezone
        if cal.isDateInToday(sunrise)    { return "today" }
        if cal.isDateInTomorrow(sunrise) { return "tomorrow" }
        return ""
    }

    private var countdownText: String? {
        guard let alarm = settings.nextAlarmTime else { return nil }
        let diff = alarm.timeIntervalSince(now)
        guard diff > 0 else { return nil }
        let h = Int(diff) / 3600
        let m = Int(diff) % 3600 / 60
        if h > 0 { return "The sun will rise in \(h)h \(m)m." }
        return "The sun will rise in \(m)m."
    }

    // MARK: - Weather helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Night"
        }
    }

    private var weatherIcon: String {
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 22 || hour < 5 { return "moon.stars.fill" }
        guard let code = weather.current?.weatherCode else { return "sun.max.fill" }
        switch code {
        case 0, 1:       return "sun.max.fill"
        case 2:          return "cloud.sun.fill"
        case 3:          return "cloud.fill"
        case 45, 48:     return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75, 77: return "snowflake"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86:     return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default:         return "sun.max.fill"
        }
    }

}

#Preview {
    HomeView()
        .environment(AlarmSettings.shared)
}
