import Domain
import Foundation
import Observation

/// タスクの追加・編集シートの状態とロジック。
///
/// 締切・実施時間・通知は「設定するかどうか」と「値」を分けて持つ。
/// トグルを OFF にしても入力済みの値を保持し、ON に戻したときに入力し直さなくて済むようにするため。
@MainActor
@Observable
public final class TaskEditorViewModel: Identifiable {
    public var title: String
    public var categoryID: TaskCategory.ID?
    public var hasDueDate: Bool
    public var dueDate: Date
    public var hasSchedule: Bool
    /// 実施日と開始時刻
    public var scheduleStart: Date
    /// 終了時刻。日付部分は使わず、`scheduleStart` と同じ日として扱う
    public var scheduleEnd: Date
    public var hasNotification: Bool
    public var notifyAt: Date
    public var urlText: String
    public var memo: String
    public private(set) var errorMessage: String?

    public let categories: [TaskCategory]

    public var isNew: Bool { original == nil }
    public var canSave: Bool { !trimmedTitle.isEmpty }

    private let original: TaskItem?
    private let taskService: TaskService
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    /// - Parameters:
    ///   - task: 編集するタスク。`nil` なら新規作成
    ///   - defaultCategoryID: 新規作成時に選択しておくカテゴリ
    public init(
        task: TaskItem?,
        categories: [TaskCategory],
        defaultCategoryID: TaskCategory.ID? = nil,
        taskService: TaskService,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        let current = now()
        let defaultStart =
            calendar.nextDate(
                after: current,
                matching: DateComponents(minute: 0),
                matchingPolicy: .nextTime
            ) ?? current

        original = task
        self.categories = categories
        self.taskService = taskService
        self.now = now
        self.calendar = calendar

        title = task?.title ?? ""
        categoryID = task?.categoryID ?? defaultCategoryID
        hasDueDate = task?.dueDate != nil
        dueDate = task?.dueDate ?? calendar.date(byAdding: .day, value: 7, to: current) ?? current
        hasSchedule = task?.schedule != nil
        scheduleStart = task?.schedule?.start ?? defaultStart
        scheduleEnd = task?.schedule?.end ?? defaultStart.addingTimeInterval(3_600)
        hasNotification = task?.notifyAt != nil
        notifyAt = task?.notifyAt ?? defaultStart
        urlText = task?.url?.absoluteString ?? ""
        memo = task?.memo ?? ""
    }

    /// 保存に成功したら `true` を返す。失敗時は `errorMessage` に理由が入る
    public func save() async -> Bool {
        guard canSave else { return false }
        let url: URL?
        switch parseURL() {
        case .empty:
            url = nil
        case .valid(let parsed):
            url = parsed
        case .invalid:
            errorMessage = "URL は https:// から入力してください"
            return false
        }

        let task = makeTask(url: url)
        do {
            if isNew {
                try await taskService.add(task)
            } else {
                try await taskService.update(task)
            }
            return true
        } catch {
            errorMessage = "保存できませんでした"
            return false
        }
    }

    /// 削除に成功したら `true` を返す
    public func delete() async -> Bool {
        guard let original else { return false }
        do {
            try await taskService.delete(id: original.id)
            return true
        } catch {
            errorMessage = "削除できませんでした"
            return false
        }
    }

    public func dismissError() {
        errorMessage = nil
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum URLInput {
        case empty
        case valid(URL)
        case invalid
    }

    /// スキームのない文字列（example.com など）は開けないリンクになるため不正として扱う
    private func parseURL() -> URLInput {
        let text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return .empty
        }
        guard let url = URL(string: text), url.scheme != nil else { return .invalid }
        return .valid(url)
    }

    private func makeTask(url: URL?) -> TaskItem {
        TaskItem(
            id: original?.id ?? UUID(),
            title: trimmedTitle,
            isCompleted: original?.isCompleted ?? false,
            createdAt: original?.createdAt ?? now(),
            categoryID: categoryID,
            dueDate: hasDueDate ? dueDate : nil,
            schedule: hasSchedule ? makeSchedule() : nil,
            notifyAt: hasNotification ? notifyAt : nil,
            url: url,
            memo: memo
        )
    }

    private func makeSchedule() -> TaskSchedule {
        let endTime = TimeOfDay(date: scheduleEnd, calendar: calendar)
        return TaskSchedule(start: scheduleStart, end: endTime.date(on: scheduleStart, calendar: calendar))
    }
}
