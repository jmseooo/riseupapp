import SwiftUI

// 배경(AnimatedOrbsBackground)과 텍스트(GlassTimeTextA)가 공유하는 orb 파라미터.
// 두 곳에서 완전히 동일한 값을 써야 orb 위치가 정확히 일치함.
enum OrbData {
    struct Orb {
        let x, y, r, s: Double   // x·y: 화면 비율 위치, r: 반경 비율, s: 속도
        let c: Color
    }

    static let orbs: [Orb] = [
        Orb(x: 0.15, y: 0.28, r: 0.44, s: 0.28, c: Color(red: 0.50, green: 0.18, blue: 0.92)),
        Orb(x: 0.78, y: 0.38, r: 0.40, s: 0.35, c: Color(red: 1.00, green: 0.40, blue: 0.10)),
        Orb(x: 0.45, y: 0.68, r: 0.38, s: 0.30, c: Color(red: 0.10, green: 0.78, blue: 1.00)),
        Orb(x: 0.22, y: 0.62, r: 0.35, s: 0.42, c: Color(red: 0.95, green: 0.18, blue: 0.58)),
        Orb(x: 0.68, y: 0.80, r: 0.32, s: 0.36, c: Color(red: 0.55, green: 0.88, blue: 0.18)),
    ]
}
