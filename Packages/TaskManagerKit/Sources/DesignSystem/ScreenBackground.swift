import SwiftUI

/// タブで切り替える画面の背景。
///
/// ガラスの部品は無地の上だと縁が見えにくいため、淡いグラデーションを敷く。
/// 画面ごとに背景が違うと切り替えたときに違和感が出るため、どの画面もこれを使う
public struct ScreenBackground: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [.indigo.opacity(0.14), .orange.opacity(0.08), .blue.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
}
