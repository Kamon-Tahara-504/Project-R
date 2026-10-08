import DomainTestSupport
import Testing

@testable import HomeFeature

struct HomeFormatterTests {
    @Test("ゲージ内の時刻は AM/PM の付かない 24 時間表記にする")
    func gaugeTimeTextUsesTwentyFourHourClock() {
        let calendar = TestCalendar.calendar
        #expect(HomeFormatter.gaugeTimeText(TestCalendar.date(2026, 1, 1, 0, 5), calendar: calendar) == "0:05")
        #expect(HomeFormatter.gaugeTimeText(TestCalendar.date(2026, 1, 1, 9, 41), calendar: calendar) == "9:41")
        #expect(HomeFormatter.gaugeTimeText(TestCalendar.date(2026, 1, 1, 18, 30), calendar: calendar) == "18:30")
    }
}
