import Domain
import Foundation
import Observation
import TaskEditorFeature

/// ホーム画面の状態とロジック。今日実施するタスクを見せる
@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var tasks: [TaskItem] = []
    public private(set) var categories: [TaskCategory] = []
    /// 「今日」の基準日時。読み込みのたびに更新する
    public private(set) var currentDate: Date
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
        currentDate = now()
    }

    /// 実施日が今日のタスク。開始時刻の早い順
    public var todayTasks: [TaskItem] {
        tasks
            .filter { $0.isScheduled(on: currentDate, calendar: calendar) }
            .sorted { ($0.schedule?.start ?? .distantFuture) < ($1.schedule?.start ?? .distantFuture) }
    }

    public func load() async {
        currentDate = now()
        do {
            categories = try await categoryRepository.fetchAll()
            tasks = try await taskService.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "タスクを読み込めませんでした"
        }
    }

    public func makeEditor(for task: TaskItem) -> TaskEditorViewModel {
        TaskEditorViewModel(
            task: task,
            categories: categories,
            taskService: taskService,
            now: now,
            calendar: calendar
        )
    }

    /// 例: 「11:30AM-12:30PM」
    public func timeRangeText(for task: TaskItem) -> String? {
        task.schedule.map { HomeFormatter.timeRangeText($0, calendar: calendar) }
    }

    public func dismissError() {
        errorMessage = nil
    }
}
