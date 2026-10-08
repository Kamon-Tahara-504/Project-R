import Domain
import DomainTestSupport
import Foundation
import Testing

struct UsageTimeSettingsTests {
    private let calendar = TestCalendar.calendar

    private func settings(start: (Int, Int), end: (Int, Int), isEnabled: Bool = true) -> UsageTimeSettings {
        UsageTimeSettings(
            isEnabled: isEnabled,
            start: TimeOfDay(hour: start.0, minute: start.1),
            end: TimeOfDay(hour: end.0, minute: end.1)
        )
    }

    @Test("無効なときは常に使える")
    func disabledAllowsAnyTime() {
        let usageTime = settings(start: (8, 0), end: (20, 0), isEnabled: false)
        #expect(usageTime.allowsAccess(at: TestCalendar.date(2026, 1, 1, 3, 0), calendar: calendar))
    }

    @Test(
        "同じ日の時間帯では、開始以上・終了未満だけ使える",
        arguments: [
            (7, 59, false),
            (8, 0, true),
            (12, 0, true),
            (19, 59, true),
            (20, 0, false),
        ]
    )
    func sameDayWindow(hour: Int, minute: Int, expected: Bool) {
        let usageTime = settings(start: (8, 0), end: (20, 0))
        let date = TestCalendar.date(2026, 1, 1, hour, minute)
        #expect(usageTime.allowsAccess(at: date, calendar: calendar) == expected)
    }

    @Test(
        "日をまたぐ時間帯にも対応する",
        arguments: [
            (21, 59, false),
            (22, 0, true),
            (0, 30, true),
            (1, 59, true),
            (2, 0, false),
        ]
    )
    func overnightWindow(hour: Int, minute: Int, expected: Bool) {
        let usageTime = settings(start: (22, 0), end: (2, 0))
        let date = TestCalendar.date(2026, 1, 1, hour, minute)
        #expect(usageTime.allowsAccess(at: date, calendar: calendar) == expected)
    }

    @Test("開始と終了が同じなら制限しない")
    func sameStartAndEndAllowsAnyTime() {
        let usageTime = settings(start: (8, 0), end: (8, 0))
        #expect(usageTime.allowsAccess(at: TestCalendar.date(2026, 1, 1, 3, 0), calendar: calendar))
    }
}
