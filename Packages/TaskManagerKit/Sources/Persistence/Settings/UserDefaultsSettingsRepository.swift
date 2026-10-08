import Domain
import Foundation

/// UserDefaults による `SettingsRepository` の実装。
///
/// 設定は件数の少ない単純な値なので、SwiftData ではなく UserDefaults に JSON でまとめて保存する。
public final class UserDefaultsSettingsRepository: SettingsRepository {
    static let key = "appSettings"

    // UserDefaults はスレッドセーフと文書化されているが、SDK 上は Sendable が付いていないため明示的に許可する
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        guard let data = defaults.data(forKey: Self.key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            // 未保存、または項目の変更で読めなくなった場合は初期値で動かす
            return .default
        }
        return settings
    }

    public func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
