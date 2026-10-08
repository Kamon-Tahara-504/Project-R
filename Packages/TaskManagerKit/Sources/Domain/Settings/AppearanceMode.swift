/// アプリの外観（ライト / ダーク）の選び方
public enum AppearanceMode: String, CaseIterable, Codable, Sendable {
    /// 端末の設定に合わせる
    case system
    case light
    case dark
}
