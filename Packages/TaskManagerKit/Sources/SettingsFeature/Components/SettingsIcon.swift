import SwiftUI

/// 設定項目の左に置く、色付きの角丸アイコン。iOS の設定アプリに見た目を合わせる
struct SettingsIcon: View {
    let systemName: String
    let color: Color
    /// 薄く表示するときの不透明度
    var opacity: Double = 1

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white.opacity(opacity))
            .frame(width: SettingsMetrics.iconSize, height: SettingsMetrics.iconSize)
            .background(color.opacity(opacity), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    HStack {
        SettingsIcon(systemName: "hourglass", color: .indigo)
        SettingsIcon(systemName: "bell.badge.fill", color: .red)
    }
}
