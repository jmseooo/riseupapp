import SwiftUI
import SwiftData
import WeatherKit

struct PersonalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]

    @State private var showAddTodo = false
    @State private var newTodoText = ""

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        calendarCard
                            .padding(.horizontal, DS.hPad)
                    }
                    .padding(.top, 8)

                    weatherAttribution
                        .padding(.top, 16)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
        .background(SwipeBackEnabler())
        .sheet(isPresented: $showAddTodo) {
            addTodoSheet
        }
    }

    // MARK: - WeatherKit attribution

    private var weatherAttribution: some View {
        let weather = WeatherService.shared
        let legalURL = weather.attribution?.legalPageURL
            ?? URL(string: "https://weatherkit.apple.com/legal-attribution.html")!
        let markURL = weather.attribution?.combinedMarkLightURL

        return HStack(spacing: 4) {
            Spacer()
            Link(destination: legalURL) {
                HStack(spacing: 4) {
                    if let markURL {
                        AsyncImage(url: markURL) { img in
                            img.resizable().scaledToFit()
                        } placeholder: {
                            EmptyView()
                        }
                        .frame(height: 12)
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

    // MARK: - Nav bar

    private var navBar: some View {
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
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Calendar card

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
            // Sunrise time labels
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Group {
                        if let day = days[i], day.sunriseTime != nil {
                            Text(day.timeLabel)
                                .font(.prompt(10))
                                .foregroundStyle(Color.rTextSub)
                        } else {
                            Text(" ").font(.prompt(10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Day number dots
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Group {
                        if let day = days[i] {
                            dayCell(day)
                        } else {
                            Color.clear.frame(width: 34, height: 34)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func dayCell(_ day: DayData) -> some View {
        let woke = settings.wokeUp(on: day.date)
        let highlighted = day.isToday || woke

        return ZStack {
            if highlighted {
                Circle()
                    .fill(day.isToday ? Color.rOrange : Color(hex: "#FFB199"))
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

    // MARK: - Data helpers

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
                    latitude:  settings.latitude,
                    longitude: settings.longitude,
                    date:      date
                )
                let isToday = cal.isDateInToday(date)
                let isFuture = date > today && !isToday
                return DayData(
                    date:        date,
                    dayNumber:   offset + 1,
                    sunriseTime: sunrise,
                    isToday:     isToday,
                    isPast:      !isToday && !isFuture
                )
            }
        }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: Date())
    }

    // MARK: - TODO section

    private var todoSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TODO")
                    .font(.prompt(12, weight: .medium))
                    .foregroundStyle(Color.rTextGray)
                    .padding(.leading, 10)
                Spacer()
                Button { showAddTodo = true } label: {
                    Text("add")
                        .font(.prompt(12))
                        .foregroundStyle(Color.rBlackWarm)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.rSurfaceGlass)
                        .clipShape(Capsule())
                        .cardShadow()
                }
            }
            .padding(.horizontal, DS.hPad)

            VStack(spacing: 0) {
                ForEach(todos) { item in
                    todoRow(item: item)
                }
            }
            .padding(.horizontal, DS.hPad)
            .padding(.top, 16)
        }
    }

    private func todoRow(item: TodoItem) -> some View {
        HStack(spacing: 14) {
            Button {
                item.isDone.toggle()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.rTextWarm, lineWidth: 1)
                        .frame(width: 22, height: 22)
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
            Rectangle()
                .fill(Color.rBorder)
                .frame(height: 1)
        }
    }

    // MARK: - Add todo sheet

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
                let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    modelContext.insert(TodoItem(text: trimmed))
                    newTodoText = ""
                }
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

// MARK: - DayData

struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let sunriseTime: Date?
    let isToday: Bool
    let isPast: Bool

    var timeLabel: String {
        guard let t = sunriseTime else { return "" }
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        return f.string(from: t)
    }

    var sunriseMinutes: CGFloat? {
        guard let t = sunriseTime else { return nil }
        let c = Calendar.current
        return CGFloat(c.component(.hour, from: t) * 60 + c.component(.minute, from: t))
    }
}

#Preview {
    NavigationStack {
        PersonalView()
            .environment(AlarmSettings.shared)
    }
    .modelContainer(for: TodoItem.self, inMemory: true)
}
