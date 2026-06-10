
import SwiftUI
import Combine

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
                        .padding(.top, 8)
                        .transition(.opacity)
                    }

                    // ── Divider ────────────────────────────────────────────
                    if !isPinchExpanded {
                        Rectangle()
                            .fill(Color.rDivider)
                            .frame(height: 1)
                            .padding(.top, 20)
                            .transition(.opacity)
                    }

                    Spacer()

                    // ── Sunrise time ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(dayLabel)
                                    .font(.pretendard(13, weight: .semibold))
                                    .foregroundStyle(Color.rTextSub)
                                Text("sunrise time")
                                    .font(.pretendard(13, weight: .semibold))
                                    .foregroundStyle(Color.rTextSub)
                            }
                            Spacer()
                        }

                        GlassTimeTextA(timeString: timeString)
                            .offset(x: wobble, y: floatY)
                            .scaleEffect(isPinchExpanded ? 1.5 : 1.0, anchor: .topLeading)
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPinchExpanded)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                                    floatY = 3.5
                                }
                            }

                        // reset 버튼 — 시간 텍스트 바로 아래
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settings.offsetMinutes = 0
                            }
                        } label: {
                            Text("reset")
                                .font(.pretendard(17, weight: .semibold))
                                .foregroundStyle(Color.rTextSub)
                        }
                        .opacity(settings.offsetMinutes != 0 ? 1 : 0)
                        .disabled(settings.offsetMinutes == 0)
                        .animation(.easeInOut(duration: 0.2), value: settings.offsetMinutes != 0)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, DS.hPad)

                    // ── Countdown ──────────────────────────────────────────
                    if !isPinchExpanded, let cd = countdownText {
                        Text(cd)
                            .font(.prompt(18))
                            .foregroundStyle(Color.rBlackWarm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.hPad)
                            .padding(.top, 10)
                            .transition(.opacity)
                    }

                    Spacer()

                    // ── Debug info ────────────────────────────────────────
                    if !isPinchExpanded {
                        Text(debugInfo)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.hPad)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }

                    // ── Alarm card ─────────────────────────────────────────
                    if !isPinchExpanded {
                        alarmCard
                            .padding(.horizontal, DS.hPad)
                            .padding(.bottom, 16)
                            .transition(.opacity)
                    }

                    // ── Bottom nav ─────────────────────────────────────────
                    if !isPinchExpanded {
                        bottomNav
                            .padding(.bottom, 24)
                            .transition(.opacity)
                    }
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
                    .onChanged { _ in
                        guard !isPinching else { return }
                        isPinching = true
                        withAnimation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true)) {
                            wobble = 5
                        }
                    }
                    .onEnded { _ in
                        isPinching = false
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
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
            .onReceive(ticker) { now = $0 }
            .sheet(isPresented: $showAppSettings) {
                AppSettingsView()
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

    // MARK: - Sub-views

    private var temperatureView: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(weather.current.map { "\(Int($0.temperature.rounded()))" } ?? "--")
                .font(.rajdhani(18))
                .foregroundStyle(Color.rTextMuted)
            Text("°")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.rTextMuted)
        }
    }

    private var weatherConditionView: some View {
        HStack(spacing: 6) {
            Image(systemName: weatherIcon)
                .font(.system(size: 22))
                .foregroundStyle(Color.rTextMuted)
            Text(greeting)
                .font(.prompt(18, weight: .semiBold))
                .foregroundStyle(Color.rTextMuted)
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
                        }
                    }
                }
        }
        .padding(.horizontal, 20)
        .frame(height: 71)
        .background(Color.rSurfaceGlass)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .cardShadow()
    }

    private var bottomNav: some View {
        HStack(spacing: 24) {
            NavigationLink {
                PersonalView()
                    .environment(settings)
            } label: {
                Text("personal")
                    .font(.prompt(18))
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
