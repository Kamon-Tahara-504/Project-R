import Domain
import Foundation
import Testing

@testable import Persistence

@MainActor
struct SwiftDataTaskRepositoryTests {
    private let repository: SwiftDataTaskRepository

    init() throws {
        repository = SwiftDataTaskRepository(container: try ModelContainerFactory.make(isStoredInMemoryOnly: true))
    }

    @Test("追加したタスクを作成日時の新しい順に取得できる")
    func fetchAllReturnsNewestFirst() async throws {
        let older = TaskItem(title: "古いタスク", createdAt: Date(timeIntervalSince1970: 0))
        let newer = TaskItem(title: "新しいタスク", createdAt: Date(timeIntervalSince1970: 100))

        try await repository.add(older)
        try await repository.add(newer)

        #expect(try await repository.fetchAll() == [newer, older])
    }

    @Test("タスクを更新できる")
    func update() async throws {
        var task = TaskItem(title: "更新前")
        try await repository.add(task)

        task.title = "更新後"
        task.completedAt = Date(timeIntervalSince1970: 200)
        try await repository.update(task)

        #expect(try await repository.fetchAll() == [task])
    }

    @Test("完了日時を記録する前に完了したタスクは、作成日時を完了日時として読み出す")
    func legacyCompletedTaskUsesCreatedAt() {
        let createdAt = Date(timeIntervalSince1970: 100)
        let record = TaskItemRecord(id: UUID(), title: "以前のタスク", isCompleted: true, createdAt: createdAt)

        #expect(record.toDomain().completedAt == createdAt)
    }

    @Test("タスクを削除できる")
    func delete() async throws {
        let task = TaskItem(title: "削除対象")
        try await repository.add(task)

        try await repository.delete(id: task.id)

        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test("追加した項目をすべて保存して読み出せる")
    func roundTripsAllFields() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let task = TaskItem(
            title: "課題",
            categoryID: UUID(),
            dueDate: Date(timeIntervalSince1970: 5_000),
            schedule: TaskSchedule(start: start, end: start.addingTimeInterval(3_600)),
            notifyAt: Date(timeIntervalSince1970: 4_000),
            url: URL(string: "https://example.com"),
            memo: "メモ"
        )

        try await repository.add(task)

        #expect(try await repository.fetchAll() == [task])
    }

    @Test("全削除するとタスクがなくなる")
    func deleteAll() async throws {
        try await repository.add(TaskItem(title: "A"))
        try await repository.add(TaskItem(title: "B"))

        try await repository.deleteAll()

        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test("存在しないタスクの更新は notFound になる")
    func updateMissingTaskThrowsNotFound() async throws {
        let task = TaskItem(title: "未保存")

        await #expect(throws: TaskRepositoryError.notFound(id: task.id)) {
            try await repository.update(task)
        }
    }
}
