import Foundation

/// アプリ全体で扱うタスク。
///
/// 保存方式（SwiftData など）に依存しない値型として定義し、画面やロジックはこの型だけを扱う。
/// `Task` という名前は Swift Concurrency の `Task` と衝突するため避けている。
public struct TaskItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public let createdAt: Date
    /// `nil` は未分類
    public var categoryID: TaskCategory.ID?
    /// 締切。タスク画面の残り日数表示に使う
    public var dueDate: Date?
    /// 実施する時間帯。ホームの「今日のタスク」はこの開始日で判定する
    public var schedule: TaskSchedule?
    /// 通知する日時。1タスクにつき1件
    public var notifyAt: Date?
    public var url: URL?
    public var memo: String

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        categoryID: TaskCategory.ID? = nil,
        dueDate: Date? = nil,
        schedule: TaskSchedule? = nil,
        notifyAt: Date? = nil,
        url: URL? = nil,
        memo: String = ""
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.categoryID = categoryID
        self.dueDate = dueDate
        self.schedule = schedule
        self.notifyAt = notifyAt
        self.url = url
        self.memo = memo
    }

    /// 締切までの残り日数。
    ///
    /// 時刻ではなく日付単位で数えるため、締切当日は 0、締切を過ぎていれば負の値になる。
    /// 締切がなければ `nil`。
    public func remainingDays(from now: Date, calendar: Calendar = .current) -> Int? {
        guard let dueDate else { return nil }
        let today = calendar.startOfDay(for: now)
        let dueDay = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: today, to: dueDay).day
    }

    /// 指定した日に実施予定かどうか。開始日時の日付で判定する
    public func isScheduled(on day: Date, calendar: Calendar = .current) -> Bool {
        guard let schedule else { return false }
        return calendar.isDate(schedule.start, inSameDayAs: day)
    }
}
