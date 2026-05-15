import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            WeatherBackground(condition: .sunrise)

            VStack(spacing: 16) {
                Text("riseup")
                    .font(.radioCanadaBig(52))
                    .foregroundStyle(Color.rBlackWarm)

                ProgressView()
                    .tint(Color.rTextMuted)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
