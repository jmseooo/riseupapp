import SwiftUI
import SwiftData

struct TodoView: View {
    @Environment(AlarmSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]

    @State private var isAdding = false
    @State private var newTodoText = ""
    @FocusState private var fieldFocused: Bool

    private let weather = WeatherService.shared

    var body: some View {
        ZStack {
            WeatherThemeBackground(
                weather: weather.current,
                hour: Calendar.current.component(.hour, from: Date())
            )

            VStack(spacing: 0) {
                // ── Header ─────────────────────────────────────────────
                HStack {
                    Text("TODO")
                        .font(.prompt(12, weight: .medium))
                        .foregroundStyle(Color.rTextGray)
                    Spacer()
                    Button { startAdding() } label: {
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
                .padding(.top, 60)

                // ── Todo list ──────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(todos) { item in
                            todoRow(item: item)
                        }
                        if isAdding {
                            inlineAddRow
                        }
                    }
                    .padding(.horizontal, DS.hPad)
                    .padding(.top, 16)
                }

                Spacer()

                // ── 추가 button ────────────────────────────────────────
                Button { handleAddButton() } label: {
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

            TextField("할 일을 입력하세요", text: $newTodoText)
                .font(.pretendard(16, weight: .medium))
                .foregroundStyle(Color.rBlackWarm)
                .focused($fieldFocused)
                .onSubmit { saveAndExit() }

            Spacer()
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.rBorder)
                .frame(height: 1)
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

    private func startAdding() {
        isAdding = true
        fieldFocused = true
    }

    private func handleAddButton() {
        if isAdding {
            saveAndExit()
        } else {
            startAdding()
        }
    }

    private func saveAndExit() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            modelContext.insert(TodoItem(text: trimmed))
            newTodoText = ""
        }
        isAdding = false
        fieldFocused = false
    }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            vc.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

#Preview {
    NavigationStack {
        TodoView()
            .environment(AlarmSettings.shared)
    }
    .modelContainer(for: TodoItem.self, inMemory: true)
}
