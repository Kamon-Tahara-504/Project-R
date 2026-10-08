import Domain
import Foundation
import Observation
import TaskEditorFeature

/// タスク画面の並び順
public enum TaskSortOrder: CaseIterable, Identifiable, Sendable {
    /// 締切の近い順。締切のないタスクは末尾
    case dueDate
    /// 作成日時の新しい順
    case createdAt

    public var id: Self { self }

    public var title: String {
        switch self {
        case .dueDate: "締切順"
        case .createdAt: "作成順"
        }
    }
}

/// タスク画面の状態とロジック。
///
/// SwiftData の `@Query` による自動更新は使わず、Repository 経由で取得した結果を自分で保持する。
/// 画面を保存方式から切り離し、モックでテストできるようにするため。
@MainActor
@Observable
public final class TaskListViewModel {
    public private(set) var tasks: [TaskItem] = []
    public private(set) var categories: [TaskCategory] = []
    /// `nil` は「全て」（全件表示）
    public var selectedCategoryID: TaskCategory.ID?
    public var sortOrder: TaskSortOrder = .dueDate
    /// 表示中の追加・編集シート。
    ///
    /// 画面の外（タブバーの作成ボタン）からも開けるよう、ビューではなくここで持つ
    public var editor: TaskEditorViewModel?
    /// 直近の操作で発生したエラー。画面に表示するための文言を保持する
    public private(set) var errorMessage: String?

    private let taskService: TaskService
    private let categoryRepository: any CategoryRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        taskService: TaskService,
        categoryRepository: any CategoryRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        self.taskService = taskService
        self.categoryRepository = categoryRepository
        self.now = now
        self.calendar = calendar
    }

    /// 選択中のカテゴリで絞り込み、並び順を適用したタスク
    public var visibleTasks: [TaskItem] {
        let filtered = tasks.filter { task in
            guard let selectedCategoryID else { return true }
            return task.categoryID == selectedCategoryID
        }
        return filtered.sorted(by: areInIncreasingOrder)
    }

    /// 見出しに添える件数。選択中のカテゴリで表示しているタスク（完了済みを含む）を数える
    public var visibleTaskCountText: String {
        "\(visibleTasks.count)件のタスク"
    }

    public func load() async {
        do {
            categories = try await categoryRepository.fetchAll()
            tasks = try await taskService.fetchAll()
            // 他の画面で選択中のカテゴリが消えていたら「全て」に戻す
            if let selectedCategoryID, !categories.contains(where: { $0.id == selectedCategoryID }) {
                self.selectedCategoryID = nil
            }
            errorMessage = nil
        } catch {
            errorMessage = "タスクを読み込めませんでした"
        }
    }

    public func toggleCompletion(_ task: TaskItem) async {
        await perform("タスクを更新できませんでした") {
            try await taskService.toggleCompletion(task)
        }
    }

    public func delete(_ task: TaskItem) async {
        await perform("タスクを削除できませんでした") {
            try await taskService.delete(id: task.id)
        }
    }

    public func addCategory(named name: String, color: CategoryColor) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (categories.map(\.sortOrder).max() ?? -1) + 1
        let category = TaskCategory(name: trimmed, sortOrder: nextOrder, color: color)
        await perform("カテゴリを追加できませんでした") {
            try await categoryRepository.add(category)
            selectedCategoryID = category.id
        }
    }

    public func deleteCategory(_ category: TaskCategory) async {
        await perform("カテゴリを削除できませんでした") {
            try await categoryRepository.delete(id: category.id)
            if selectedCategoryID == category.id {
                selectedCategoryID = nil
            }
        }
    }

    /// 新規作成のシートを開く。選択中のカテゴリを初期値にする
    public func startCreatingTask() {
        editor = makeEditor(for: nil)
    }

    public func startEditing(_ task: TaskItem) {
        editor = makeEditor(for: task)
    }

    /// - Parameter task: `nil` なら新規作成
    private func makeEditor(for task: TaskItem?) -> TaskEditorViewModel {
        TaskEditorViewModel(
            task: task,
            categories: categories,
            defaultCategoryID: selectedCategoryID,
            taskService: taskService,
            now: now,
            calendar: calendar
        )
    }

    /// タスクカードの色分けに使う、タスクが属するカテゴリの色。未分類のタスクは `nil`
    public func categoryColor(for task: TaskItem) -> CategoryColor? {
        guard let categoryID = task.categoryID else { return nil }
        return categories.first { $0.id == categoryID }?.color
    }

    public func dueDateText(for task: TaskItem) -> String? {
        task.dueDate.map { TaskListFormatter.dueDateText($0, calendar: calendar) }
    }

    public func remainingDaysText(for task: TaskItem) -> String? {
        TaskListFormatter.remainingDaysText(for: task, now: now(), calendar: calendar)
    }

    /// 締切が1週間以内、または過ぎているか。残り日数を強調表示するために使う
    public func isDueSoon(_ task: TaskItem) -> Bool {
        guard let days = task.remainingDays(from: now(), calendar: calendar) else { return false }
        return days <= 7
    }

    public func dismissError() {
        errorMessage = nil
    }

    /// 変更操作を実行し、成功したら一覧を読み込み直す。失敗したら `message` を表示する
    private func perform(_ message: String, _ operation: () async throws -> Void) async {
        do {
            try await operation()
            await load()
        } catch {
            errorMessage = message
        }
    }

    private func areInIncreasingOrder(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if sortOrder == .dueDate, lhs.dueDate != rhs.dueDate {
            switch (lhs.dueDate, rhs.dueDate) {
            case (let lhsDate?, let rhsDate?): return lhsDate < rhsDate
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): break
            }
        }
        return lhs.createdAt > rhs.createdAt
    }
}
