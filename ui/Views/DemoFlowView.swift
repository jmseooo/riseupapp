// DemoFlowView.swift
// 프레젠테이션 전용 — 앱 전체 플로우 시연용 임시 파일
// 프로덕션 코드와 무관. 기존 코드에 영향 없음.

import SwiftUI
import SwiftData

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
                DemoWakeUpView { withAnimation(.easeInOut(duration: 0.6)) { step = .onboarding } }
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
                Text(timeString)
                    .font(.pretendard(60, weight: .semibold))
                    .foregroundStyle(Color.rTextPrimary)
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
                        DemoPersonalView().environment(settings)
                    } label: {
                        Image(systemName: "sun.min.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.rBlackWarm)
                    }
                    NavigationLink {
                        DemoTodoView().environment(settings)
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

// MARK: - DemoPersonalView

private struct DemoPersonalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmSettings.self) private var settings

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                // nav bar
                ZStack {
                    Text("record")
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(Color.rBlackWarm)
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.rBlackWarm)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 30)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    calendarCard
                        .padding(.horizontal, DS.hPad)
                        .padding(.top, 8)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
        .background(SwipeBackEnabler())
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Location")
                    .font(.prompt(12, weight: .medium))
                    .foregroundStyle(Color.rTextGray)
                Text(monthLabel)
                    .font(.pretendard(30, weight: .semibold))
                    .foregroundStyle(.black)
            }
            VStack(spacing: 16) {
                ForEach(0..<monthWeeks.count, id: \.self) { i in
                    weekRow(monthWeeks[i])
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .cardShadow()
    }

    private func weekRow(_ days: [DayData?]) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Group {
                        if let day = days[i], day.sunriseTime != nil {
                            Text(day.demoTimeLabel)
                                .font(.prompt(10))
                                .foregroundStyle(Color.rTextSub)
                        } else {
                            Text(" ").font(.prompt(10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Group {
                        if let day = days[i] { dayCell(day) }
                        else { Color.clear.frame(width: 34, height: 34) }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func dayCell(_ day: DayData) -> some View {
        let woke = settings.wokeUp(on: day.date)
        let demoMarked = day.dayNumber == 1 || day.dayNumber == 3
        let highlighted = day.isToday || woke || demoMarked
        return ZStack {
            if highlighted {
                Circle()
                    .fill(Color.rOrange)
                    .frame(width: 34, height: 34)
            }
            Text("\(day.dayNumber)")
                .font(.pretendard(13, weight: highlighted ? .semibold : .regular))
                .foregroundStyle(
                    highlighted ? .white
                    : day.isPast ? Color.rTextPrimary
                    : Color.rTextSub
                )
        }
        .frame(width: 34, height: 34)
    }

    private var monthWeeks: [[DayData?]] {
        var cal = Calendar.current
        cal.firstWeekday = 1
        let today = Date()
        let comps = cal.dateComponents([.year, .month], from: today)
        guard let firstOfMonth = cal.date(from: comps) else { return [] }
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)!.count
        let totalWeeks = Int(ceil(Double(firstWeekday + daysInMonth) / 7.0))
        return (0..<totalWeeks).map { w in
            (0..<7).map { d -> DayData? in
                let offset = w * 7 + d - firstWeekday
                guard offset >= 0, offset < daysInMonth,
                      let date = cal.date(byAdding: .day, value: offset, to: firstOfMonth)
                else { return nil }
                let sunrise = SunriseService.sunriseTime(
                    latitude: settings.latitude, longitude: settings.longitude, date: date)
                let isToday = cal.isDateInToday(date)
                let isFuture = date > today && !isToday
                return DayData(date: date, dayNumber: offset + 1, sunriseTime: sunrise,
                               isToday: isToday, isPast: !isToday && !isFuture)
            }
        }
    }

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM"
        return f.string(from: Date())
    }
}

extension DayData {
    var demoTimeLabel: String {
        guard sunriseTime != nil else { return "" }
        let minute = (dayNumber * 17 + 3) % 60
        return String(format: "5:%02d", minute)
    }
}

// MARK: - DemoTodoView

private struct DemoTodoView: View {
    @Environment(AlarmSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]

    @State private var isAdding = false
    @State private var newTodoText = ""

    var body: some View {
        ZStack {
            WeatherThemeBackground(weather: demoWeather, hour: demoHour)

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.rTextPrimary)
                    }
                    Spacer()
                    Text("TODO")
                        .font(.prompt(12, weight: .medium))
                        .foregroundStyle(Color.rTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 76)

                List {
                    ForEach(todos) { item in
                        todoRow(item: item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: DS.hPad, bottom: 0, trailing: DS.hPad))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { modelContext.delete(item) } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                    if isAdding {
                        inlineAddRow
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: DS.hPad, bottom: 0, trailing: DS.hPad))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.top, 16)

                Button { if isAdding { saveAndExit() } else { isAdding = true } } label: {
                    Text("추가")
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.btnH)
                        .background(Color.rBlackWarm)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, DS.hPad)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea()
        .background(SwipeBackEnabler())
    }

    private var inlineAddRow: some View {
        HStack(spacing: 14) {
            Circle()
                .strokeBorder(Color.rTextWarm, lineWidth: 1)
                .frame(width: 22, height: 22)
            DemoAutoFocusTextField(
                text: $newTodoText,
                placeholder: "할 일을 입력하세요",
                onSubmit: saveAndExit
            )
            .frame(height: 50)
            Spacer()
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.rBorder).frame(height: 1)
        }
    }

    private func todoRow(item: TodoItem) -> some View {
        HStack(spacing: 14) {
            Button { item.isDone.toggle() } label: {
                ZStack {
                    Circle().strokeBorder(Color.rTextWarm, lineWidth: 1).frame(width: 22, height: 22)
                    if item.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.rBlackWarm)
                    }
                }
            }
            Text(item.text)
                .font(.pretendard(16, weight: .medium))
                .foregroundStyle(item.isDone ? Color.rTextSub : Color.rBlackWarm)
                .strikethrough(item.isDone, color: Color.rTextSub)
            Spacer()
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.rBorder).frame(height: 1)
        }
    }

    private func saveAndExit() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { modelContext.insert(TodoItem(text: trimmed)); newTodoText = "" }
        isAdding = false
    }
}

// MARK: - DemoAutoFocusTextField

import UIKit

private struct DemoAutoFocusTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.font = UIFont(name: "Pretendard-Medium", size: 16)
        field.textColor = UIColor(Color.rBlackWarm)
        field.returnKeyType = .done
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
        if !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DemoAutoFocusTextField
        init(_ parent: DemoAutoFocusTextField) { self.parent = parent }

        @objc func textChanged(_ field: UITextField) { parent.text = field.text ?? "" }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit(); return true
        }
    }
}

// MARK: - DemoWakeUpView

private struct DemoWakeUpView: View {
    @Environment(AlarmSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]
    let onWokeUp: () -> Void

    @State private var showAddTodo = false
    @State private var newTodoText = ""

    var body: some View {
        ZStack {
            WeatherThemeBackground(weather: demoWeather, hour: demoHour)

            VStack(alignment: .leading, spacing: 0) {
                Text("Good morning")
                    .font(.pretendard(34, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.hPad)
                    .padding(.top, 72)

                todoSection
                    .padding(.top, 32)

                Spacer()

                Button {
                    onWokeUp()
                } label: {
                    Text("I woke up")
                        .font(.pretendard(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.btnH)
                        .background(Color.rOrange)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, DS.hPad)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showAddTodo) { addTodoSheet }
    }

    private var todoSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TODO")
                    .font(.prompt(12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, 10)
                Spacer()
                Button { showAddTodo = true } label: {
                    Text("add")
                        .font(.prompt(12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, DS.hPad)

            VStack(spacing: 0) {
                ForEach(todos) { item in
                    HStack(spacing: 14) {
                        Button { item.isDone.toggle() } label: {
                            ZStack {
                                Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1).frame(width: 22, height: 22)
                                if item.isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        Text(item.text)
                            .font(.pretendard(16, weight: .medium))
                            .foregroundStyle(item.isDone ? .white.opacity(0.40) : .white)
                            .strikethrough(item.isDone, color: .white.opacity(0.40))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, DS.hPad)
            .padding(.top, 16)
        }
    }

    private var addTodoSheet: some View {
        VStack(spacing: 20) {
            Text("새 할 일")
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(Color.rBlackWarm)
                .padding(.top, 24)
            TextField("할 일을 입력하세요", text: $newTodoText)
                .font(.pretendard(16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, DS.hPad)
            Button {
                let t = newTodoText.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { modelContext.insert(TodoItem(text: t)); newTodoText = "" }
                showAddTodo = false
            } label: {
                Text("추가")
                    .font(.pretendard(17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.btnH)
                    .background(Color.rGreenBright)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DS.hPad)
            Spacer()
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
        .background(Color.rCream.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview {
    DemoFlowView()
        .environment(AlarmSettings.shared)
}
