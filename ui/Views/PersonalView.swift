import SwiftUI
import SwiftData

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
                        sunriseCard
                            .padding(.horizontal, DS.hPad)

                        todoSection
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddTodo) {
            addTodoSheet
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("personal")
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

    // MARK: - Sunrise card

    private var sunriseCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("My Location")
                .font(.prompt(12, weight: .medium))
                .foregroundStyle(Color.rTextGray)
                .padding(.leading, 10)

            VStack(alignment: .leading, spacing: 24) {
                Text(monthLabel)
                    .font(.pretendard(30, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(spacing: 24) {
                    weekRow(weekData(offset: -1))
                    weekRow(weekData(offset: 0))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.60))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .cardShadow()
        }
    }

    private func weekRow(_ days: [DayData]) -> some View {
        VStack(spacing: 18) {
            SunriseSparkline(days: days)
                .frame(height: 8)

            VStack(spacing: 2) {
                // Sunrise time labels
                HStack(spacing: 10) {
                    ForEach(days) { day in
                        Text(day.timeLabel)
                            .font(.prompt(12))
                            .foregroundStyle(Color.rTextSub)
                            .frame(width: 34, alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }

                // Day number pills
                HStack(spacing: 10) {
                    ForEach(days) { day in
                        Text("\(day.dayNumber)")
                            .font(.pretendard(13))
                            .foregroundStyle(Color.rBlackWarm)
                            .frame(width: 34, height: 34)
                            .background(pillColor(for: day))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func pillColor(for day: DayData) -> Color {
        if day.isToday { return Color(hex: "#FF7A3D") }
        if day.isPast && settings.wokeUp(on: day.date) { return Color(hex: "#FFB199") }
        return .clear
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
                .foregroundStyle(item.isDone
                    ? Color.rTextSub
                    : Color.rBlackWarm)
                .strikethrough(item.isDone,
                               color: Color.rTextSub)

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

    // MARK: - Data helpers

    private func weekData(offset: Int) -> [DayData] {
        let cal = Calendar.current
        let today = Date()

        // Find Sunday of the target week
        let weekday = cal.component(.weekday, from: today) - 1
        let sundayOffset = -weekday + (offset * 7)
        guard let sunday = cal.date(byAdding: .day, value: sundayOffset, to: today) else { return [] }

        return (0..<7).compactMap { i in
            guard let date = cal.date(byAdding: .day, value: i, to: sunday) else { return nil }
            let sunrise = SunriseService.sunriseTime(
                latitude:  settings.latitude,
                longitude: settings.longitude,
                date: date
            )
            let dayNum = cal.component(.day, from: date)
            let isToday = cal.isDateInToday(date)
            let isFuture = date > today && !isToday
            return DayData(
                date: date,
                dayNumber: dayNum,
                sunriseTime: sunrise,
                isToday: isToday,
                isPast: !isToday && !isFuture
            )
        }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: Date()).uppercased()
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let sunriseTime: Date?
    let isToday: Bool
    let isPast: Bool

    var timeLabel: String {
        guard let t = sunriseTime else { return "--:--" }
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        return f.string(from: t)
    }

    var sunriseMinutes: CGFloat? {
        guard let t = sunriseTime else { return nil }
        let c = Calendar.current
        let h = c.component(.hour, from: t)
        let m = c.component(.minute, from: t)
        return CGFloat(h * 60 + m)
    }
}

// MARK: - Sparkline

struct SunriseSparkline: View {
    let days: [DayData]

    var body: some View {
        Canvas { ctx, size in
            let path = buildPath(size: size)
            ctx.stroke(path, with: .color(Color(hex: "#C9C1B4")), lineWidth: 1.5)
        }
    }

    private func buildPath(size: CGSize) -> Path {
        let mins = days.compactMap(\.sunriseMinutes)
        guard mins.count > 1, days.count > 1 else {
            return Path { p in
                p.move(to: CGPoint(x: 0, y: size.height / 2))
                p.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            }
        }
        let lo   = mins.min()!
        let hi   = mins.max()!
        let span = max(hi - lo, 1)
        let step = size.width / CGFloat(days.count - 1)

        var pts: [CGPoint] = []
        var di = 0
        for i in 0..<days.count {
            if days[i].sunriseMinutes != nil {
                let x = CGFloat(i) * step
                let y = size.height - ((mins[di] - lo) / span) * size.height
                pts.append(CGPoint(x: x, y: y))
                di += 1
            }
        }

        return Path { path in
            guard pts.count > 1 else { return }
            path.move(to: pts[0])
            for i in 1..<pts.count {
                let p = pts[i - 1], q = pts[i]
                let mx = (p.x + q.x) / 2
                path.addCurve(to: q,
                              control1: CGPoint(x: mx, y: p.y),
                              control2: CGPoint(x: mx, y: q.y))
            }
        }
    }
}

#Preview {
    PersonalView()
        .environment(AlarmSettings.shared)
        .modelContainer(for: TodoItem.self, inMemory: true)
}
