import Domain
import DomainTestSupport
import Foundation
import Testing

struct TaskItemTests {
    private let calendar = TestCalendar.calendar

    @Test(
        "残り日数は時刻ではなく日付単位で数える",
        arguments: [
            (TestCalendar.date(2026, 1, 8, 0, 0), 7),
            (TestCalendar.date(2026, 1, 1, 23, 59), 0),
            (TestCalendar.date(2025, 12, 31, 23, 59), -1),
        ]
    )
    func remainingDays(dueDate: Date, expected: Int) {
        let task = TaskItem(title: "課題", dueDate: dueDate)
        let now = TestCalendar.date(2026, 1, 1, 22, 0)
        #expect(task.remainingDays(from: now, calendar: calendar) == expected)
    }

    @Test("締切がなければ残り日数は nil")
    func remainingDaysWithoutDueDate() {
        let task = TaskItem(title: "課題")
        #expect(task.remainingDays(from: .now, calendar: calendar) == nil)
    }

    @Test("実施日は開始日時の日付で判定する")
    func isScheduledOnStartDay() {
        let schedule = TaskSchedule(
            start: TestCalendar.date(2026, 1, 1, 23, 0),
            end: TestCalendar.date(2026, 1, 1, 23, 30)
        )
        let task = TaskItem(title: "作業", schedule: schedule)

        #expect(task.isScheduled(on: TestCalendar.date(2026, 1, 1, 9, 0), calendar: calendar))
        #expect(!task.isScheduled(on: TestCalendar.date(2026, 1, 2, 9, 0), calendar: calendar))
    }

    @Test("終了が開始より前なら開始に揃える")
    func scheduleEndIsNotBeforeStart() {
        let start = TestCalendar.date(2026, 1, 1, 12, 0)
        let schedule = TaskSchedule(start: start, end: TestCalendar.date(2026, 1, 1, 11, 0))
        #expect(schedule.end == start)
    }
}
