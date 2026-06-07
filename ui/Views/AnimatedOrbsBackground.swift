import SwiftUI

// 임시 배경 orb 레이어 — 날씨 변수 매핑 전 테스트용.
// OrbData.orbs 를 공유하여 GlassTimeTextA 의 텍스트 내부 orb와 위치가 정확히 일치.
struct AnimatedOrbsBackground: View {

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate

                for (i, o) in OrbData.orbs.enumerated() {
                    let ph = t * o.s + Double(i) * 1.40
                    let cx = (o.x + sin(ph)        * 0.11) * size.width
                    let cy = (o.y + cos(ph * 0.85) * 0.10) * size.height
                    let r  = o.r * min(size.width, size.height) * 1.35

                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: cx - r, y: cy - r, width: r * 2, height: r * 2
                        )),
                        with: .radialGradient(
                            Gradient(colors: [o.c.opacity(0.88), .clear]),
                            center: CGPoint(x: cx, y: cy),
                            startRadius: 0,
                            endRadius: r
                        )
                    )
                }
            }
        }
        .blur(radius: 30)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()
        AnimatedOrbsBackground()
    }
}
