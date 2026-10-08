import Domain
import Foundation
import Notifications
import Persistence

/// アプリ全体で共有する依存関係。
///
/// 具体的な実装（SwiftData、UserDefaults、UserNotifications）を知っているのはここだけにし、
/// 画面には Domain のプロトコルとして渡す。
@MainActor
struct AppDependencies {
    /// UI テストから起動されたときに付ける起動引数
    static let uiTestingArgument = "-UITesting"

    let taskService: TaskService
    let categoryRepository: any CategoryRepository
    let settingsRepository: any SettingsRepository

    /// - Parameter isUITesting: `true` なら、端末のデータに触れないようメモリ上の保存先と専用の UserDefaults を使う。
    ///   利用時間の制限も初期値（OFF）になるため、テストの実行時刻によって休憩画面に阻まれることがない
    static func make(isUITesting: Bool) throws -> AppDependencies {
        let defaults = isUITesting ? makeUITestingDefaults() : .standard
        let container = try ModelContainerFactory.make(isStoredInMemoryOnly: isUITesting)

        let categoryRepository = SwiftDataCategoryRepository(container: container)
        try categoryRepository.removeLegacyDefaultsIfNeeded(defaults: defaults)

        let settingsRepository = UserDefaultsSettingsRepository(defaults: defaults)
        let taskService = TaskService(
            taskRepository: SwiftDataTaskRepository(container: container),
            notificationScheduler: UserNotificationScheduler(),
            settingsRepository: settingsRepository
        )
        return AppDependencies(
            taskService: taskService,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        )
    }

    /// 前回の UI テストの設定が残らないよう、毎回空の状態から始める
    private static func makeUITestingDefaults() -> UserDefaults {
        let suiteName = "UITesting"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
