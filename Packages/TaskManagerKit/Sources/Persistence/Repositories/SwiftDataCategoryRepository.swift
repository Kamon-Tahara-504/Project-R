import Domain
import Foundation
import SwiftData

/// SwiftData による `CategoryRepository` の実装。
///
/// スレッドの扱いは `SwiftDataTaskRepository` と同じ理由でメインアクターに集約している。
@MainActor
public final class SwiftDataCategoryRepository: CategoryRepository {
    /// 以前の版で初回起動時に投入していたカテゴリ。現在は固定カテゴリを「全て」だけにしたため投入しない
    static let legacyDefaultCategoryNames = ["学校課題", "自主制作", "コンテスト"]
    /// 以前の版が初期カテゴリを投入したときに立てていたフラグ
    static let didSeedDefaultsKey = "didSeedDefaultCategories"

    // context の寿命を保証するためにコンテナ自体を保持する（SwiftDataTaskRepository を参照）
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchAll() async throws -> [TaskCategory] {
        let descriptor = FetchDescriptor<TaskCategoryRecord>(sortBy: [SortDescriptor(\.sortOrder)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func add(_ category: TaskCategory) async throws {
        context.insert(TaskCategoryRecord(category))
        try context.save()
    }

    public func delete(id: TaskCategory.ID) async throws {
        try deleteCategory(id: id)
        try context.save()
    }

    /// 以前の版が投入した初期カテゴリを削除する。属していたタスクは未分類に戻す。
    ///
    /// 投入済みフラグが立っている端末でだけ実行し、終わったらフラグを消す。
    /// こうすることで、削除後にユーザーが同じ名前のカテゴリを作っても、次回起動時に消されない。
    public func removeLegacyDefaultsIfNeeded(defaults: UserDefaults = .standard) throws {
        guard defaults.bool(forKey: Self.didSeedDefaultsKey) else { return }
        let legacyNames = Self.legacyDefaultCategoryNames
        let legacyCategories = try context.fetch(
            FetchDescriptor<TaskCategoryRecord>(predicate: #Predicate { legacyNames.contains($0.name) })
        )
        for category in legacyCategories {
            try deleteCategory(id: category.id)
        }
        try context.save()
        defaults.removeObject(forKey: Self.didSeedDefaultsKey)
    }

    /// カテゴリを削除し、属していたタスクを未分類に戻す。保存は呼び出し側で行う
    private func deleteCategory(id: TaskCategory.ID) throws {
        let categoryID: UUID? = id
        let tasks = try context.fetch(
            FetchDescriptor<TaskItemRecord>(predicate: #Predicate { $0.categoryID == categoryID })
        )
        for task in tasks {
            task.categoryID = nil
        }

        let categories = try context.fetch(
            FetchDescriptor<TaskCategoryRecord>(predicate: #Predicate { $0.id == id })
        )
        for category in categories {
            context.delete(category)
        }
    }
}
