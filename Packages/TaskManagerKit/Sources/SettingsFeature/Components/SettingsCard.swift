import DesignSystem
import SwiftUI

/// 設定画面のカードと行の寸法。区切り線を文字の始まりに揃えるため、アイコンと余白の値を共有する
enum SettingsMetrics {
    /// 行の高さ。時刻の選択ボタンが入る行が最も高いため、それに他の行を揃える
    static let rowHeight: CGFloat = 67
    static let horizontalPadding: CGFloat = 16
    static let iconSize: CGFloat = 29
    /// アイコンと項目名の間隔
    static let labelSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 24
}

/// 設定の行をまとめるリキッドグラスのカード。タスク画面のカードと見た目を揃えるため、共通のガラス背景を使う
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .glassBackground(
            in: RoundedRectangle(cornerRadius: SettingsMetrics.cardCornerRadius, style: .continuous),
            // カード自体は押しても何も起きないため、押したときの反応は付けない
            isInteractive: false
        )
    }
}

/// カードの中の 1 行。高さと左右の余白を揃える
struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: SettingsMetrics.rowHeight, alignment: .leading)
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
    }
}

/// カードの中の行同士の区切り線。iOS の設定アプリと同じく、アイコンの右（項目名の始まり）から引く
struct SettingsRowDivider: View {
    var body: some View {
        Divider()
            .padding(
                .leading, SettingsMetrics.horizontalPadding + SettingsMetrics.iconSize + SettingsMetrics.labelSpacing
            )
    }
}

/// 色付きのアイコンと項目名
struct SettingsLabel: View {
    let title: String
    let systemName: String
    let color: Color

    var body: some View {
        HStack(spacing: SettingsMetrics.labelSpacing) {
            SettingsIcon(systemName: systemName, color: color)
            Text(title)
        }
    }
}
