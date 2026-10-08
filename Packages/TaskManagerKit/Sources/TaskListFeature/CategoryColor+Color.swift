import Domain
import SwiftUI

extension CategoryColor {
    /// 画面に表示する色。タスクカードに薄く敷いても文字が読めるよう、システムの標準色を使う
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        }
    }

    /// この色で塗った上に載せる文字の色。黄色は明るく白い文字が読めないため黒にする
    var foregroundOnFill: Color {
        self == .yellow ? .black : .white
    }

    /// 色選択のボタンを読み上げるときの名前
    var accessibilityName: String {
        switch self {
        case .red: "赤"
        case .orange: "オレンジ"
        case .yellow: "黄"
        case .green: "緑"
        case .teal: "ティール"
        case .blue: "青"
        case .purple: "紫"
        case .pink: "ピンク"
        }
    }
}
