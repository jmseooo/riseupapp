import SwiftUI

// 폰트 실험용 — GlassTimeTextA와 동일한 구조, 폰트만 AkiraExpanded로 교체
struct GlassTimeTextDraft: View {
    let timeString: String
    @State private var globalOffset: CGPoint = .zero

    private var screenSize: CGSize {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.size ?? CGSize(width: 390, height: 844)
    }

    var body: some View {
        Text(timeString)
            .font(.akiraExpanded(110))
            .foregroundStyle(Color.clear)
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
                        let sw  = screenSize.width
                        let sh  = screenSize.height
                        let mid = CGPoint(x: size.width / 2, y: size.height / 2)

                        let resolved = ctx.resolve(
                            Text(timeString)
                                .font(.akiraExpanded(110))
                        )

                        ctx.drawLayer { layer in
                            for (i, o) in OrbData.orbs.enumerated() {
                                let ph = t * o.s + Double(i) * 1.40
                                let gx = (o.x + sin(ph)        * 0.11) * sw
                                let gy = (o.y + cos(ph * 0.85) * 0.10) * sh
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
                            layer.blendMode = .destinationIn
                            layer.draw(resolved, at: mid, anchor: .center)
                        }

                        ctx.blendMode = .screen
                        ctx.opacity   = 0.38
                        ctx.draw(resolved, at: mid, anchor: .center)
                    }
                }
                .allowsHitTesting(false)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()
        AnimatedOrbsBackground()
        VStack(spacing: 40) {
            GlassTimeTextDraft(timeString: "5:48")
            GlassTimeTextA(timeString: "5:48")
        }
    }
}
