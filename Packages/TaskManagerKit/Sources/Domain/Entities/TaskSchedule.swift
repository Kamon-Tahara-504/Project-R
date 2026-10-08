import Foundation

/// タスクを実施する時間帯
public struct TaskSchedule: Equatable, Sendable {
    public let start: Date
    /// 常に `start` 以降になる
    public let end: Date

    /// `end` が `start` より前の場合は、開始と同時刻に揃える
    public init(start: Date, end: Date) {
        self.start = start
        self.end = max(start, end)
    }
}
