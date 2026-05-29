import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationStatus: NotificationStatus = .unknown

    enum NotificationStatus {
        case unknown, granted, denied
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("알림")
                    notificationRow
                    sectionLabel("문의")
                    contactRow
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task { await checkNotificationStatus() }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("settings")
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(Color.rBlackWarm)

            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.rTextSub)
                }
            }
        }
        .padding(.horizontal, DS.hPad)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Rows

    private var notificationRow: some View {
        HStack {
            Text("팝업 허용")
                .font(.pretendard(16, weight: .medium))
                .foregroundStyle(Color.rBlackWarm)

            Spacer()

            switch notificationStatus {
            case .granted:
                Text("허용됨")
                    .font(.pretendard(14))
                    .foregroundStyle(Color.rTextSub)
            case .denied:
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("설정에서 허용 →")
                        .font(.pretendard(14))
                        .foregroundStyle(Color(hex: "#FF7A3D"))
                }
            case .unknown:
                EmptyView()
            }
        }
        .padding(.horizontal, DS.hPad)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.rBorder).frame(height: 1)
        }
    }

    private var contactRow: some View {
        Button {
            if let url = URL(string: "mailto:jinminseo1001@gmail.com") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Text("문의하기")
                    .font(.pretendard(16, weight: .medium))
                    .foregroundStyle(Color.rBlackWarm)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.rTextSub)
            }
            .padding(.horizontal, DS.hPad)
            .padding(.vertical, 18)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.rBorder).frame(height: 1)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.prompt(12, weight: .medium))
            .foregroundStyle(Color.rTextGray)
            .padding(.horizontal, DS.hPad + 10)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationStatus = .granted
            case .denied:
                notificationStatus = .denied
            default:
                notificationStatus = .unknown
            }
        }
    }
}

#Preview {
    AppSettingsView()
}
