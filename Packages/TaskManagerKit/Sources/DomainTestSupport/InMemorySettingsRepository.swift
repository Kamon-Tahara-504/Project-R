import Domain
import Synchronization

/// メモリ上だけに保存する `SettingsRepository`
public final class InMemorySettingsRepository: SettingsRepository {
    // 同期 API を Sendable に保つため、actor ではなく Mutex で守る
    private let storage: Mutex<AppSettings>

    public init(settings: AppSettings = .default) {
        storage = Mutex(settings)
    }

    public func load() -> AppSettings {
        storage.withLock { $0 }
    }

    public func save(_ settings: AppSettings) {
        storage.withLock { $0 = settings }
    }
}
