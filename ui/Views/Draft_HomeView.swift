import SwiftUI
import Combine

// 디자인 실험용 파일 — 기존 HomeView.swift에 영향 없음
// 완성되면 HomeView.swift에 적용

struct Draft_HomeView: View {
    @Environment(AlarmSettings.self) private var settings
    @State private var now = Date()
    private let weather = WeatherService.shared

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    @State private var showAppSettings = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Draft_WeatherThemeBackground(
                    weather: weather.current,
                    hour: Calendar.current.component(.hour, from: now)
                )

                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        temperatureView
                        Spacer()
                        weatherConditionView
                        Button {
                            showAppSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.rTextMuted)
                                .padding(.top, 30)
                                .padding(.leading, 12)
                        }
                    }
                    .padding(.horizontal, DS.hPad)
                    .padding(.top, 8)

                    Rectangle()
                        .fill(Color.rDivider)
                        .frame(height: 1)
                        .padding(.top, 20)

                    Spacer()

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

                    if let cd = countdownText {
                        Text(cd)
                            .font(.prompt(18))
                            .foregroundStyle(Color.rBlackWarm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.hPad)
                            .padding(.top, 10)
                    }

                    Spacer()

                    alarmCard
                        .padding(.horizontal, DS.hPad)
                        .padding(.bottom, 16)

                    bottomNav
                        .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .onReceive(ticker) { now = $0 }
            .sheet(isPresented: $showAppSettings) {
                AppSettingsView()
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
    Draft_HomeView()
        .environment(AlarmSettings.shared)
}
