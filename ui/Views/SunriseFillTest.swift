import SwiftUI

// ── 테스트 전용 파일 ──────────────────────────────────────────────────────────
// 일출 시간 도달 시 오렌지 색이 아래서부터 차오르는 효과 프로토타입.
// 프로덕션 코드와 연결 없음. Preview에서 바로 확인 가능.

private let sunriseOrange = Color(red: 1.0, green: 0.478, blue: 0.239) // #FF7A3D

// MARK: - Wave shape

private struct RisingWave: Shape {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amplitude: CGFloat = 6
        let wavelength = rect.width * 0.7

        path.move(to: CGPoint(x: 0, y: amplitude))

        for x in stride(from: CGFloat(0), through: rect.width, by: 1.5) {
            let y = amplitude * sin((x / wavelength) * .pi * 2 - phase) + amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Test view

struct SunriseFillTest: View {
    @State private var fillFraction: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    @State private var isFilling = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 배경
                Color(red: 0.06, green: 0.04, blue: 0.12)
                    .ignoresSafeArea()

                // 오렌지 fill — 아래서부터 차오름
                RisingWave(phase: wavePhase)
                    .fill(sunriseOrange.opacity(0.90))
                    .frame(height: geo.size.height * fillFraction + 20)
                    .animation(.easeInOut(duration: 3.5), value: fillFraction)

                // 콘텐츠 레이어
                VStack(spacing: 0) {
                    Spacer()

                    Text("6:24")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundStyle(.white)

                    Text("sunrise time")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, 4)

                    Spacer()

                    // 테스트 버튼
                    Button {
                        if isFilling {
                            isFilling = false
                            withAnimation(.easeInOut(duration: 1.0)) { fillFraction = 0 }
                        } else {
                            isFilling = true
                            withAnimation(.easeInOut(duration: 3.5)) { fillFraction = 1.0 }
                        }
                    } label: {
                        Text(isFilling ? "Reset" : "일출 시간 도달 →")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 60)
                }
            }
            .onAppear {
                // 파도 위상 애니메이션 — 무한 반복
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    wavePhase = .pi * 2
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SunriseFillTest()
}
