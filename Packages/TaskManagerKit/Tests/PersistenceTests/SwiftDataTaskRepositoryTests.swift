import Domain
import Foundation
import Persistence
import Testing

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
        task.isCompleted = true
        try await repository.update(task)

        #expect(try await repository.fetchAll() == [task])
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
