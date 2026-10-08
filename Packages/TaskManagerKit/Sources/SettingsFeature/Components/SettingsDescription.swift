import SwiftUI

/// カードの最後に置く説明文。操作する行と見分けられるよう、上に区切り線を引いて文章の高さにする
struct SettingsDescription: View {
    /// 区切り線と説明文の間隔
    private static let spacing: CGFloat = 10

    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            Divider()
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                // 長い説明文が 1 行に切り詰められないよう、縦に伸ばす
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.bottom, 14)
    }
}
