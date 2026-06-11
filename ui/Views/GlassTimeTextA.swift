import SwiftUI

// 시안 A — Canvas Orb-Through-Text
// AnimatedOrbsBackground와 동일한 orb 파라미터 + 전역 좌표 오프셋을 사용하여
// 배경 orb가 정확히 동일한 위치에서 글자 내부를 통과하게 렌더링.
struct GlassTimeTextA: View {
    let timeString: String
    @State private var globalOffset: CGPoint = .zero

    var body: some View {
        Text(timeString)
            .font(.pretendard(60, weight: .semibold))
            .foregroundStyle(Color.clear)   // 레이아웃만 잡음
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            let f = geo.frame(in: .global)
                            globalOffset = CGPoint(x: f.minX, y: f.minY)
                        }
                }
            )
            .overlay {
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in

                        let t   = tl.date.timeIntervalSinceReferenceDate
                        let sw  = UIScreen.main.bounds.width
                        let sh  = UIScreen.main.bounds.height
                        let mid = CGPoint(x: size.width / 2, y: size.height / 2)

                        let resolved = ctx.resolve(
                            Text(timeString)
                                .font(.pretendard(60, weight: .semibold))
                        )

                        // ── orb를 전역 좌표로 계산 → 로컬로 변환 → 텍스트로 마스킹 ──
                        // 흰 베이스 — orb가 없는 영역도 흰색으로
                        ctx.drawLayer { layer in
                            layer.fill(
                                Path(CGRect(origin: .zero, size: size)),
                                with: .color(.white)
                            )
                            layer.blendMode = .destinationIn
                            layer.draw(resolved, at: mid, anchor: .center)
                        }

                        ctx.drawLayer { layer in
                            for (i, o) in OrbData.orbs.enumerated() {
                                let ph = t * o.s + Double(i) * 1.40

                                // AnimatedOrbsBackground와 완전히 동일한 공식
                                let gx = (o.x + sin(ph)        * 0.11) * sw
                                let gy = (o.y + cos(ph * 0.85) * 0.10) * sh

                                // 캔버스 로컬 좌표 = 전역 위치 - 텍스트 뷰 원점
                                let lx = gx - globalOffset.x
                                let ly = gy - globalOffset.y
                                let r  = o.r * min(sw, sh) * 1.35

                                layer.fill(
                                    Path(ellipseIn: CGRect(
                                        x: lx - r, y: ly - r,
                                        width: r * 2, height: r * 2
                                    )),
                                    with: .radialGradient(
                                        Gradient(colors: [o.c.opacity(0.95), .clear]),
                                        center: CGPoint(x: lx, y: ly),
                                        startRadius: 0,
                                        endRadius: r
                                    )
                                )
                            }

                            // 텍스트 형태로만 잘라냄
                            layer.blendMode = .destinationIn
                            layer.draw(resolved, at: mid, anchor: .center)
                        }

                        // 흰 rim
                        ctx.blendMode = .normal
                        ctx.opacity   = 0.0
                        ctx.draw(resolved, at: mid, anchor: .center)
                    }
                }
                .allowsHitTesting(false)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()
        AnimatedOrbsBackground()
        GlassTimeTextA(timeString: "6:24")
    }
}
