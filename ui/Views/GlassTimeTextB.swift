import SwiftUI

// 시안 B — Liquid Goo Merge
// 블룸 레이어가 인접 글자 사이를 액체처럼 이어줌.
// 변동 폭 축소: 12s 느린 주기, 블룸 반경 7pt.
struct GlassTimeTextB: View {
    let timeString: String
    @State private var hue: Double = 0

    private var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.24, green: 0.73, blue: 1.00), location: 0.00),
                .init(color: Color(red: 1.00, green: 0.31, blue: 0.64), location: 0.50),
                .init(color: Color(red: 0.58, green: 0.31, blue: 1.00), location: 1.00),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // 블룸 레이어: blur가 인접 글자 사이를 이어 액체처럼 보임
            Text(timeString)
                .font(.radioCanadaBig(110))
                .fontWeight(.black)
                .foregroundStyle(gradient)
                .blur(radius: 7)

            // 선명 레이어: 글자 형태 항상 유지
            Text(timeString)
                .font(.radioCanadaBig(110))
                .fontWeight(.black)
                .foregroundStyle(gradient)
        }
        .drawingGroup()
        .hueRotation(.degrees(hue * 360))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                hue = 1.0
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()
        GlassTimeTextB(timeString: "6:24")
    }
}
