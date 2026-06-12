import SwiftUI

struct OnboardingView: View {
    @State private var typingText = ""
    @State private var typingTask: Task<Void, Never>? = nil

    private let subtitle = "Embracing a natural circadian rhythm guided by\nthe sun's movement."

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 10) {
                Text("SUNERS")
                    .font(.pretendard(42, weight: .heavy))
                    .foregroundStyle(Color.rOrange)
                    .tracking(0.84)

                ZStack(alignment: .top) {
                    Text(subtitle).opacity(0)
                    Text(typingText)
                }
                .font(.pretendard(12))
                .foregroundStyle(Color.rOrange)
                .tracking(0.24)
                .multilineTextAlignment(.center)
            }
        }
        .onAppear { startTyping() }
    }

    private func startTyping() {
        typingTask?.cancel()
        typingText = ""
        typingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            for char in subtitle {
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: 30_000_000)
                typingText.append(char)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AlarmSettings.shared)
}
