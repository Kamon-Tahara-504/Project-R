import Foundation

/// アプリ設定の永続化を抽象化する窓口。
///
/// 設定は起動直後の休憩画面の判定にも使うため、待たずに読める同期 API にしている。
public protocol SettingsRepository: Sendable {
    /// 保存されていなければ `AppSettings.default` を返す
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}
