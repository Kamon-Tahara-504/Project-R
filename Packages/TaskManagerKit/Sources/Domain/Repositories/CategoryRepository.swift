import Foundation

/// カテゴリの永続化を抽象化する窓口
public protocol CategoryRepository: Sendable {
    /// `sortOrder` の昇順で返す
    func fetchAll() async throws -> [TaskCategory]
    func add(_ category: TaskCategory) async throws
    /// 削除したカテゴリに属していたタスクは未分類に戻す
    func delete(id: TaskCategory.ID) async throws
}
