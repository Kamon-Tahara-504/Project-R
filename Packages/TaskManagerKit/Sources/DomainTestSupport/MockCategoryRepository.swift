import Domain

/// 保存先を配列で置き換えた `CategoryRepository`。
///
/// 実装と同じく、削除時にタスクを未分類に戻せるよう `MockTaskRepository` を受け取れる。
public actor MockCategoryRepository: CategoryRepository {
    public private(set) var categories: [TaskCategory]
    private let taskRepository: MockTaskRepository?

    public init(categories: [TaskCategory] = [], taskRepository: MockTaskRepository? = nil) {
        self.categories = categories
        self.taskRepository = taskRepository
    }

    public func fetchAll() async throws -> [TaskCategory] {
        categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    public func add(_ category: TaskCategory) async throws {
        categories.append(category)
    }

    public func delete(id: TaskCategory.ID) async throws {
        categories.removeAll { $0.id == id }
        guard let taskRepository else { return }
        for var task in try await taskRepository.fetchAll() where task.categoryID == id {
            task.categoryID = nil
            try await taskRepository.update(task)
        }
    }
}
