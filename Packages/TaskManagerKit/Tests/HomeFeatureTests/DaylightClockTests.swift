import DomainTestSupport
import Foundation
import Testing

@testable import HomeFeature

struct DaylightClockTests {
    private let calendar = TestCalendar.calendar
    /// 20 秒周期の区切りにあたる時刻
    private let cycleStart = Date(timeIntervalSinceReferenceDate: 20 * 1_000_000)

    private func hourAndMinute(_ date: Date) -> [Int?] {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return [components.hour, components.minute]
    }

    @Test("実時間ではそのままの時刻を返す")
    func realTimeReturnsNow() {
        let now = TestCalendar.date(2026, 1, 1, 9, 30)
        #expect(DaylightClock.realTime.date(at: now, calendar: calendar) == now)
    }

    @Test("早送りでは周期の経過割合に応じて 0:00〜24:00 を進む")
    func acceleratedMapsCycleToDay() {
        let clock = DaylightClock.accelerated(secondsPerDay: 20)
        #expect(hourAndMinute(clock.date(at: cycleStart, calendar: calendar)) == [0, 0])
        #expect(hourAndMinute(clock.date(at: cycleStart.addingTimeInterval(5), calendar: calendar)) == [6, 0])
        #expect(hourAndMinute(clock.date(at: cycleStart.addingTimeInterval(10), calendar: calendar)) == [12, 0])
    }

    @Test("早送りでは 1 周期が終わると 0:00 に戻る")
    func acceleratedLoops() {
        let clock = DaylightClock.accelerated(secondsPerDay: 20)
        #expect(hourAndMinute(clock.date(at: cycleStart.addingTimeInterval(20), calendar: calendar)) == [0, 0])
    }
}
