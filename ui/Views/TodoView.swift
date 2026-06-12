import SwiftUI
import SwiftData
import UIKit

struct TodoView: View {
    @Environment(AlarmSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]

    @State private var isAdding = false
    @State private var newTodoText = ""
    @State private var hour = Calendar.current.component(.hour, from: Date())

    private let weather = WeatherService.shared

    var body: some View {
        ZStack {
            WeatherThemeBackground(
                weather: weather.current,
                hour: hour
            )

            VStack(spacing: 0) {
                // ── Header ─────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("TODO")
                        .font(.prompt(12, weight: .medium))
                        .foregroundStyle(Color.rTextGray)
                    Spacer()
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 76)

                // ── Todo list ──────────────────────────────────────────
                List {
                    ForEach(todos) { item in
                        todoRow(item: item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: DS.hPad, bottom: 0, trailing: DS.hPad))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(item)
                                } label: {
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

            AutoFocusTextField(
                text: $newTodoText,
                placeholder: "할 일을 입력하세요",
                onSubmit: saveAndExit
            )
            .frame(height: 50)

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

    private func handleAddButton() {
        if isAdding { saveAndExit() } else { isAdding = true }
    }

    private func saveAndExit() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            modelContext.insert(TodoItem(text: trimmed))
            newTodoText = ""
        }
        isAdding = false
    }
}

// MARK: - AutoFocusTextField

private struct AutoFocusTextField: UIViewRepresentable {
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
        var parent: AutoFocusTextField
        init(_ parent: AutoFocusTextField) { self.parent = parent }

        @objc func textChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            return true
        }
    }
}

// MARK: - SwipeBackEnabler

struct SwipeBackEnabler: UIViewControllerRepresentable {
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
