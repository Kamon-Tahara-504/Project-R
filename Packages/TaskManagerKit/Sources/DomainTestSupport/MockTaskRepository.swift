import Domain

/// 保存先を配列で置き換えた `TaskRepository`
public actor MockTaskRepository: TaskRepository {
    public private(set) var tasks: [TaskItem]
    /// 設定すると `fetchAll()` がこのエラーを投げる
    private let fetchError: (any Error)?

    public init(tasks: [TaskItem] = [], fetchError: (any Error)? = nil) {
        self.tasks = tasks
        self.fetchError = fetchError
    }

    public func fetchAll() async throws -> [TaskItem] {
        if let fetchError {
            throw fetchError
        }
        return tasks.sorted { $0.createdAt > $1.createdAt }
    }

    public func add(_ task: TaskItem) async throws {
        tasks.append(task)
    }

    public func update(_ task: TaskItem) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw TaskRepositoryError.notFound(id: task.id)
        }
        tasks[index] = task
    }

    public func delete(id: TaskItem.ID) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw TaskRepositoryError.notFound(id: id)
        }
        tasks.remove(at: index)
    }

    public func deleteAll() async throws {
        tasks.removeAll()
    }
}
