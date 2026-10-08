import Domain

extension AppearanceMode {
    /// 設定画面の選択肢に出す名前
    var title: String {
        switch self {
        case .system: "自動"
        case .light: "ライト"
        case .dark: "ダーク"
        }
    }
}
