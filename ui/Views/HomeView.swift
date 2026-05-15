import SwiftUI
import Combine

struct HomeView: View {
    @Environment(AlarmSettings.self) private var settings
    @State private var now = Date()

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                WeatherBackground(condition: .sunrise)

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

                    // ── Alarm card ─────────────────────────────────────────
                    alarmCard
                        .padding(.horizontal, DS.hPad)
                        .padding(.bottom, 16)

                    // ── Bottom nav ─────────────────────────────────────────
                    bottomNav
                        .padding(.bottom, 48)
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
            Text("24")
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
            Image(systemName: "cloud.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.rTextMuted)
            Text("Good Afternoon")
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
        guard let alarm = settings.nextAlarmTime else { return "--:--" }
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        return f.string(from: alarm)
    }

    private var dayLabel: String {
        guard let alarm = settings.nextAlarmTime else { return "" }
        if Calendar.current.isDateInToday(alarm)    { return "today" }
        if Calendar.current.isDateInTomorrow(alarm) { return "tomorrow" }
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
}

#Preview {
    HomeView()
        .environment(AlarmSettings.shared)
}
