import Domain
import DomainTestSupport
import Foundation
import Testing

@MainActor
struct TaskServiceTests {
    private let now = TestCalendar.date(2026, 1, 1, 12, 0)
    private let repository = MockTaskRepository()
    private let scheduler = MockNotificationScheduler()
    private let settings = InMemorySettingsRepository()

    private func makeService() -> TaskService {
        let now = now
        return TaskService(
            taskRepository: repository,
            notificationScheduler: scheduler,
            settingsRepository: settings,
            now: { now }
        )
    }

    private var future: Date { now.addingTimeInterval(3600) }
    private var past: Date { now.addingTimeInterval(-3600) }

    @Test("未来の通知日時を持つタスクを追加すると通知を登録する")
    func addSchedulesNotification() async throws {
        let task = TaskItem(title: "課題", notifyAt: future)

        try await makeService().add(task)

        #expect(await scheduler.scheduledIDs == [task.id])
    }

    @Test("通知日時が過去なら登録しない")
    func pastNotifyAtIsNotScheduled() async throws {
        try await makeService().add(TaskItem(title: "課題", notifyAt: past))

        #expect(await scheduler.scheduledIDs.isEmpty)
    }

    @Test("完了にすると通知を取り消し、未完了に戻すと再登録する")
    func toggleCompletionSyncsNotification() async throws {
        let service = makeService()
        let task = TaskItem(title: "課題", notifyAt: future)
        try await service.add(task)

        let completed = try await service.toggleCompletion(task)
        #expect(await scheduler.scheduledIDs.isEmpty)

        try await service.toggleCompletion(completed)
        #expect(await scheduler.scheduledIDs == [task.id])
    }

    @Test("全体設定が OFF なら通知しない")
    func disabledNotificationsAreNotScheduled() async throws {
        settings.save(AppSettings(notificationsEnabled: false))

        try await makeService().add(TaskItem(title: "課題", notifyAt: future))

        #expect(await scheduler.scheduledIDs.isEmpty)
    }

    @Test("削除すると通知も取り消す")
    func deleteCancelsNotification() async throws {
        let service = makeService()
        let task = TaskItem(title: "課題", notifyAt: future)
        try await service.add(task)

        try await service.delete(id: task.id)

        #expect(await scheduler.scheduledIDs.isEmpty)
        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test("全削除するとタスクと通知がすべて消える")
    func deleteAllRemovesTasksAndNotifications() async throws {
        let service = makeService()
        try await service.add(TaskItem(title: "A", notifyAt: future))
        try await service.add(TaskItem(title: "B", notifyAt: future))

        try await service.deleteAll()

        #expect(try await repository.fetchAll().isEmpty)
        #expect(await scheduler.scheduledIDs.isEmpty)
    }

    @Test("通知を作り直すと、通知すべき未完了タスクだけが登録される")
    func rescheduleAllRegistersOnlyPendingFutureTasks() async throws {
        let pending = TaskItem(title: "未完了", notifyAt: future)
        let completed = TaskItem(title: "完了", isCompleted: true, notifyAt: future)
        try await repository.add(pending)
        try await repository.add(completed)

        try await makeService().rescheduleAllNotifications()

        #expect(await scheduler.scheduledIDs == [pending.id])
    }
}
