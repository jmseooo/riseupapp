import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            WeatherBackground(condition: .sunrise)

            Text("riseup")
                .font(.radioCanadaBig(52))
                .foregroundStyle(Color.rBlackWarm)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
