import Domain
import Foundation

/// タスク画面に表示する日付まわりの文言
enum TaskListFormatter {
    /// 例: 「1月1日(水)」
    static func dueDateText(_ date: Date, calendar: Calendar) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(month: .defaultDigits)月\(day: .defaultDigits)日(\(weekday: .abbreviated))",
            locale: Locale(identifier: "ja_JP"),
            timeZone: calendar.timeZone,
            calendar: calendar
        )
        return date.formatted(style)
    }

    /// 例: 「残り7日」「今日まで」「残り1ヶ月以上」「期限切れ」。締切がなければ `nil`
    static func remainingDaysText(for task: TaskItem, now: Date, calendar: Calendar) -> String? {
        guard let dueDate = task.dueDate, let days = task.remainingDays(from: now, calendar: calendar) else {
            return nil
        }
        if days < 0 {
            return "期限切れ"
        }
        if days == 0 {
            return "今日まで"
        }
        // 月によって日数が違うため、日数ではなく暦の1ヶ月後と比べる
        let oneMonthLater = calendar.date(byAdding: .month, value: 1, to: calendar.startOfDay(for: now))
        if let oneMonthLater, calendar.startOfDay(for: dueDate) >= oneMonthLater {
            return "残り1ヶ月以上"
        }
        return "残り\(days)日"
    }
}
