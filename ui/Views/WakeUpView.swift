import SwiftUI
import SwiftData

struct WakeUpView: View {
    @Environment(AlarmSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]
    var onWokeUp: () -> Void

    @State private var showAddTodo = false
    @State private var newTodoText = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            warmBlob

            VStack(alignment: .leading, spacing: 0) {
                Text("Good morning")
                    .font(.pretendard(34, weight: .semibold))
                    .foregroundStyle(Color.rBlackWarm)
                    .padding(.horizontal, DS.hPad)
                    .padding(.top, 72)

                todoSection
                    .padding(.top, 32)

                Spacer()

                Button {
                    AlarmAudioPlayer.shared.stop()
                    onWokeUp()
                } label: {
                    Text("I woke up")
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
        .onAppear {
            AlarmAudioPlayer.shared.play()
        }
        .onDisappear {
            AlarmAudioPlayer.shared.stop()
        }
        .sheet(isPresented: $showAddTodo) {
            addTodoSheet
        }
    }

    // MARK: - Background blob

    private var warmBlob: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "#FF9E72").opacity(0.55),
                        Color(hex: "#FFB199").opacity(0.30),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .frame(width: 380, height: 320)
            .blur(radius: 50)
            .offset(y: 80)
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

#Preview {
    WakeUpView { }
        .environment(AlarmSettings.shared)
        .modelContainer(for: TodoItem.self, inMemory: true)
}
