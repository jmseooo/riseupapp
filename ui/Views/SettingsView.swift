import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmSettings.self) private var settings
    @State private var locationManager = LocationManager.shared

    // Weekday display data
    private let weekdays: [(String, String)] = [
        ("Sunday",    "3/3"),
        ("Monday",    "3/4"),
        ("Tuesday",   "3/5"),
        ("Wednesday", "3/6"),
        ("Thursday",  "3/7"),
        ("Friday",    "3/8"),
        ("Saturday",  "3/9"),
    ]
    @State private var weekdayEnabled = [true, false, true, true, true, false, true]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark background from design
            Color(hex: "#383D39")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Nav bar ──────────────────────────────────────────────
                ZStack {
                    Text("setting")
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // ── Section header ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily alarms")
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("activate")
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.hPad)
                .padding(.bottom, 16)

                // ── Offset adjustment ────────────────────────────────────
                offsetSection

                Divider()
                    .background(Color.white.opacity(0.12))
                    .padding(.horizontal, DS.hPad)
                    .padding(.vertical, 8)

                // ── Day rows ─────────────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(weekdays.indices, id: \.self) { i in
                            dayRow(
                                day: weekdays[i].0,
                                date: weekdays[i].1,
                                isOn: $weekdayEnabled[i]
                            )
                        }
                    }
                    .padding(.horizontal, DS.hPad)
                }

                Spacer()
            }

            // ── Save button ───────────────────────────────────────────────
            saveButton
                .padding(.horizontal, 27)
                .padding(.bottom, 48)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Offset section

    private var offsetSection: some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("일출 기준 조정")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(offsetLabel)
                    .font(.prompt(14, weight: .semiBold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { Double(settings.offsetMinutes) },
                    set: { settings.offsetMinutes = Int($0) }
                ),
                in: -30...30,
                step: 5
            )
            .tint(Color.rGreenAccent)
            .onChange(of: settings.offsetMinutes) { _, _ in
                guard settings.isEnabled else { return }
                Task { await NotificationManager.shared.scheduleSunriseAlarm() }
            }

            HStack {
                Text("-30m")
                Spacer()
                Text("sunrise")
                Spacer()
                Text("+30m")
            }
            .font(.pretendard(11))
            .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, DS.hPad)
        .padding(.bottom, 4)
    }

    // MARK: - Day row

    private func dayRow(day: String, date: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Text(day)
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 110, alignment: .leading)

            Text(date)
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.30))
                .frame(width: 40, alignment: .leading)

            if let alarm = settings.nextAlarmTime {
                Text(alarmTimeString(alarm))
                    .font(.prompt(17, weight: .semiBold))
                    .foregroundStyle(Color.white.opacity(0.30))
            } else {
                Text("--:--")
                    .font(.prompt(17, weight: .semiBold))
                    .foregroundStyle(Color.white.opacity(0.30))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.rGreenAccent)
        }
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Save")
                .font(.pretendard(24, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: DS.btnH)
                .background(Color.rGreenBright)
                .clipShape(Capsule())
        }
    }

    // MARK: - Helpers

    private var offsetLabel: String {
        let s = settings.offsetMinutes
        if s == 0 { return "sunrise" }
        return s > 0 ? "+\(s)m" : "\(s)m"
    }

    private func alarmTimeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        return f.string(from: date)
    }
}

#Preview {
    SettingsView()
        .environment(AlarmSettings.shared)
}
