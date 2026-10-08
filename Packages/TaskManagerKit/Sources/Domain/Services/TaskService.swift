import Foundation

/// タスクの保存と通知の同期をまとめるサービス。
///
/// タスクを変更する画面は複数あり（ホーム、タスク、編集シート、設定）、
/// それぞれが通知の登録・取り消しを意識すると漏れが出るため、変更操作はここを経由させる。
@MainActor
public final class TaskService {
    private let taskRepository: any TaskRepository
    private let notificationScheduler: any TaskNotificationScheduler
    private let settingsRepository: any SettingsRepository
    private let now: @Sendable () -> Date

    public init(
        taskRepository: any TaskRepository,
        notificationScheduler: any TaskNotificationScheduler,
        settingsRepository: any SettingsRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.taskRepository = taskRepository
        self.notificationScheduler = notificationScheduler
        self.settingsRepository = settingsRepository
        self.now = now
    }

    public func fetchAll() async throws -> [TaskItem] {
        try await taskRepository.fetchAll()
    }

    public func add(_ task: TaskItem) async throws {
        try await taskRepository.add(task)
        await syncNotification(for: task)
    }

    public func update(_ task: TaskItem) async throws {
        try await taskRepository.update(task)
        await syncNotification(for: task)
    }

    /// 完了状態を反転させ、更新後のタスクを返す
    @discardableResult
    public func toggleCompletion(_ task: TaskItem) async throws -> TaskItem {
        var toggled = task
        toggled.isCompleted.toggle()
        try await update(toggled)
        return toggled
    }

    public func delete(id: TaskItem.ID) async throws {
        try await taskRepository.delete(id: id)
        await notificationScheduler.cancel(id: id)
    }

    public func deleteAll() async throws {
        try await taskRepository.deleteAll()
        await notificationScheduler.cancelAll()
    }

    public func requestNotificationAuthorization() async -> Bool {
        await notificationScheduler.requestAuthorization()
    }

    /// 通知の全体設定を切り替えたあとに呼び、登録済みの通知を設定に合わせて作り直す
    public func rescheduleAllNotifications() async throws {
        await notificationScheduler.cancelAll()
        for task in try await taskRepository.fetchAll() where shouldNotify(task) {
            await notificationScheduler.schedule(task)
        }
    }

    private func syncNotification(for task: TaskItem) async {
        if shouldNotify(task) {
            await notificationScheduler.schedule(task)
        } else {
            await notificationScheduler.cancel(id: task.id)
        }
    }

    /// 完了済み、通知日時が過去、全体設定が OFF のいずれかなら通知しない
    private func shouldNotify(_ task: TaskItem) -> Bool {
        guard settingsRepository.load().notificationsEnabled,
            !task.isCompleted,
            let notifyAt = task.notifyAt
        else {
            return false
        }
        return notifyAt > now()
    }
}
