import Foundation

/// タスクの永続化を抽象化する窓口。
///
/// Feature はこのプロトコルだけに依存し、実装（Persistence モジュール）は App で注入する。
/// 実装側のスレッド制約を隠すため、すべて async にしている。
public protocol TaskRepository: Sendable {
    /// 作成日時の新しい順に返す
    func fetchAll() async throws -> [TaskItem]
    func add(_ task: TaskItem) async throws
    /// - Throws: 対象が存在しない場合は `TaskRepositoryError.notFound`
    func update(_ task: TaskItem) async throws
    /// - Throws: 対象が存在しない場合は `TaskRepositoryError.notFound`
    func delete(id: TaskItem.ID) async throws
    func deleteAll() async throws
}

public enum TaskRepositoryError: Error, Equatable {
    case notFound(id: TaskItem.ID)
}
