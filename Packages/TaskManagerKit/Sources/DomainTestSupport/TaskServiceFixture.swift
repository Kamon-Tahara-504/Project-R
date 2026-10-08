import Domain
import Foundation

/// モック一式で組み立てた `TaskService`。Feature のテストで状態の確認にモックを直接参照できる
@MainActor
public struct TaskServiceFixture {
    public let taskRepository: MockTaskRepository
    public let categoryRepository: MockCategoryRepository
    public let notificationScheduler: MockNotificationScheduler
    public let settingsRepository: InMemorySettingsRepository
    public let service: TaskService

    public init(
        tasks: [TaskItem] = [],
        categories: [TaskCategory] = [],
        settings: AppSettings = .default,
        isNotificationAuthorized: Bool = true,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        taskRepository = MockTaskRepository(tasks: tasks)
        categoryRepository = MockCategoryRepository(categories: categories, taskRepository: taskRepository)
        notificationScheduler = MockNotificationScheduler(isAuthorized: isNotificationAuthorized)
        settingsRepository = InMemorySettingsRepository(settings: settings)
        service = TaskService(
            taskRepository: taskRepository,
            notificationScheduler: notificationScheduler,
            settingsRepository: settingsRepository,
            now: now
        )
    }
}
