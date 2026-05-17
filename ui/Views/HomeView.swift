import SwiftUI
import Combine

struct HomeView: View {
    @Environment(AlarmSettings.self) private var settings
    @State private var now = Date()
    private let weather = WeatherService.shared

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                WeatherBackground(condition: backgroundCondition)

                VStack(spacing: 0) {
                    // ── Weather row ────────────────────────────────────────
                    HStack(alignment: .top, spacing: 0) {
                        temperatureView
                        Spacer()
                        weatherConditionView
                    }
                    .padding(.horizontal, DS.hPad)
                    .padding(.top, 8)

                    // ── Divider ────────────────────────────────────────────
                    Rectangle()
                        .fill(Color.rDivider)
                        .frame(height: 1)
                        .padding(.top, 20)

                    Spacer()

                    // ── Sunrise time ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(dayLabel)
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(Color.rTextSub)
                            Text("sunrise time")
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(Color.rTextSub)
                        }

                        HStack(alignment: .center) {
                            Text(timeString)
                                .font(.radioCanadaBig(110))
                                .foregroundStyle(Color.rBlackWarm)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer()
                            Image(systemName: "chevron.up")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.rBlackWarm)
                        }
                    }
                    .padding(.horizontal, DS.hPad)

                    // ── Countdown ──────────────────────────────────────────
                    if let cd = countdownText {
                        Text(cd)
                            .font(.prompt(18))
                            .foregroundStyle(Color.rBlackWarm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.hPad)
                            .padding(.top, 10)
                    }

                    Spacer()

                    // ── Debug info ────────────────────────────────────────
                    Text(debugInfo)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.hPad)
                        .padding(.bottom, 8)

                    // ── Alarm card ─────────────────────────────────────────
                    alarmCard
                        .padding(.horizontal, DS.hPad)
                        .padding(.bottom, 16)

                    // ── Bottom nav ─────────────────────────────────────────
                    bottomNav
                        .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .onReceive(ticker) { now = $0 }
            .task {
                LocationManager.shared.updateLocation()
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
                .font(.rajdhani(62))
                .foregroundStyle(Color.rTextMuted)
            Text("°")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.rTextMuted)
                .padding(.top, 10)
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
        .padding(.top, 30)
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
                SettingsView()
                    .environment(settings)
            } label: {
                Text("setting")
                    .font(.prompt(18))
                    .foregroundStyle(Color.rBlackWarm)
            }

            NavigationLink {
                PersonalView()
                    .environment(settings)
            } label: {
                Text("personal")
                    .font(.prompt(18))
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
        let lat = String(format: "%.2f", settings.latitude)
        let lon = String(format: "%.2f", settings.longitude)
        return "일출 \(sunriseStr)  \(tempStr)  \(dateStr)  (\(lat), \(lon))"
    }

    private var timeString: String {
        guard let sunrise = settings.nextSunriseTime else { return "--:--" }
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        f.timeZone = settings.locationTimezone
        return f.string(from: sunrise)
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

    private var backgroundCondition: WeatherCondition {
        let code = weather.current?.weatherCode ?? -1
        let hour = Calendar.current.component(.hour, from: now)

        if hour >= 22 || hour < 5  { return .night }
        if hour < 7                { return (code == 0 || code == 1) ? .sunrise : daytimeCondition(code: code) }
        if hour >= 19              { return (code == 0 || code == 1) ? .sunset  : daytimeCondition(code: code) }
        if hour >= 17              { return (code == 0 || code == 1) ? .goldenHour : daytimeCondition(code: code) }
        return daytimeCondition(code: code)
    }

    private func daytimeCondition(code: Int) -> WeatherCondition {
        switch code {
        case 0, 1:           return .clearDay
        case 2:              return .partlyCloudy
        case 3:              return .cloudy
        case 45, 48:         return .fog
        case 51, 53, 55:     return .drizzle
        case 61, 63, 65,
             80, 81, 82:     return .rain
        case 71, 73, 75, 77: return .snow
        case 85, 86:         return .blizzard
        case 95, 96, 99:     return .thunderstorm
        default:             return .clearDay
        }
    }
}

#Preview {
    HomeView()
        .environment(AlarmSettings.shared)
}
