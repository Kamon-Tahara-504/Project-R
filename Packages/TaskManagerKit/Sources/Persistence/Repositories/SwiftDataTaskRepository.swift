import Domain
import Foundation
import SwiftData

/// SwiftData による `TaskRepository` の実装。
///
/// `ModelContext` は Sendable ではないため、メインアクター上の `mainContext` に処理を集約している。
/// 大量データの処理などでメインスレッドを塞ぐようになったら `@ModelActor` への移行を検討する。
@MainActor
public final class SwiftDataTaskRepository: TaskRepository {
    /// `ModelContext` はコンテナを強参照しないため、コンテナが解放されると context が無効になりクラッシュする。
    /// context の寿命を保証するためにコンテナ自体を保持する。
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchAll() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItemRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func add(_ task: TaskItem) async throws {
        context.insert(TaskItemRecord(task))
        try context.save()
    }

    public func update(_ task: TaskItem) async throws {
        let record = try findRecord(id: task.id)
        record.apply(task)
        try context.save()
    }

    public func delete(id: TaskItem.ID) async throws {
        let record = try findRecord(id: id)
        context.delete(record)
        try context.save()
    }

    public func deleteAll() async throws {
        for record in try context.fetch(FetchDescriptor<TaskItemRecord>()) {
            context.delete(record)
        }
        try context.save()
    }

    private func findRecord(id: TaskItem.ID) throws -> TaskItemRecord {
        var descriptor = FetchDescriptor<TaskItemRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            throw TaskRepositoryError.notFound(id: id)
        }
        return record
    }
}
