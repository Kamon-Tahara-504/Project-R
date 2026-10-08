import DomainTestSupport
import Testing

@testable import HomeFeature

struct RoomTintCycleTests {
    private func darkness(_ hour: Int, _ minute: Int = 0) -> Double {
        RoomTintCycle.tint(at: TestCalendar.date(2026, 1, 1, hour, minute), calendar: TestCalendar.calendar).darkness
    }

    private func isApproximately(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.0001
    }

    @Test("夜は昼より部屋が暗い")
    func nightIsDarkerThanNoon() {
        #expect(darkness(0) > darkness(12))
        #expect(isApproximately(darkness(12), 0.10))
    }

    @Test("日をまたぐ夜のあいだも同じ暗さが続く")
    func nightContinuesAcrossMidnight() {
        #expect(isApproximately(darkness(22), 0.45))
        #expect(isApproximately(darkness(2), 0.45))
    }

    @Test("節目のあいだは暗さを補間する")
    func interpolatesBetweenKeyframes() {
        // 19:00（0.38）と 20:00（0.45）の中間
        #expect(isApproximately(darkness(19, 30), 0.415))
    }
}
