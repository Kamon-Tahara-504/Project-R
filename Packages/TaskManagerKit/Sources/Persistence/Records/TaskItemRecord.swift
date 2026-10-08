import Domain
import Foundation
import SwiftData

/// `TaskItem` を SwiftData に保存するための型。
///
/// `@Model` はクラスであることやマクロへの依存を伴うため、モジュール外には公開せず、
/// Repository の中で `TaskItem` と相互に変換する。
/// 後から追加した項目は、既存データを自動移行で引き継げるよう任意またはデフォルト値付きにしている。
@Model
final class TaskItemRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var categoryID: UUID?
    var dueDate: Date?
    // TaskSchedule は値型のまま保存できないため、開始と終了に分けて持つ
    var scheduleStart: Date?
    var scheduleEnd: Date?
    var notifyAt: Date?
    var url: URL?
    var memo: String = ""

    init(id: UUID, title: String, isCompleted: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

extension TaskItemRecord {
    convenience init(_ task: TaskItem) {
        self.init(id: task.id, title: task.title, isCompleted: task.isCompleted, createdAt: task.createdAt)
        apply(task)
    }

    func toDomain() -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            isCompleted: isCompleted,
            createdAt: createdAt,
            categoryID: categoryID,
            dueDate: dueDate,
            schedule: schedule,
            notifyAt: notifyAt,
            url: url,
            memo: memo
        )
    }

    /// `id` と `createdAt` は作成時に確定する値なので更新対象に含めない
    func apply(_ task: TaskItem) {
        title = task.title
        isCompleted = task.isCompleted
        categoryID = task.categoryID
        dueDate = task.dueDate
        scheduleStart = task.schedule?.start
        scheduleEnd = task.schedule?.end
        notifyAt = task.notifyAt
        url = task.url
        memo = task.memo
    }

    private var schedule: TaskSchedule? {
        guard let scheduleStart, let scheduleEnd else { return nil }
        return TaskSchedule(start: scheduleStart, end: scheduleEnd)
    }
}
