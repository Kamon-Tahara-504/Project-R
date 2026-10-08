import DomainTestSupport
import Testing

@testable import HomeFeature

struct DaylightCycleTests {
    private func sky(_ hour: Int, _ minute: Int = 0) -> SkyState {
        DaylightCycle.sky(at: TestCalendar.date(2026, 1, 1, hour, minute), calendar: TestCalendar.calendar)
    }

    private func isApproximately(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.0001
    }

    @Test("日の出の時刻に太陽の表示に切り替わる")
    func sunAtSunrise() {
        #expect(sky(5, 59).body == .moon)
        #expect(sky(6).body == .sun)
    }

    @Test("日の入りの時刻に月の表示に切り替わる")
    func moonAtSunset() {
        #expect(sky(17, 59).body == .sun)
        #expect(sky(18).body == .moon)
    }

    @Test("真夜中は月を表示する")
    func moonAtMidnight() {
        #expect(sky(0).body == .moon)
    }

    @Test("空の明るさは真夜中に 0、正午に 1、日の出・日の入りでちょうど中間になる")
    func daylightPeaksAtNoon() {
        #expect(isApproximately(sky(0).daylight, 0))
        #expect(isApproximately(sky(6).daylight, 0.5))
        #expect(isApproximately(sky(12).daylight, 1))
        #expect(isApproximately(sky(18).daylight, 0.5))
    }

    @Test("雲は日中だけ、星は夜だけ表示し、日の出・日の入りの前後で入れ替わる")
    func cloudVisibilityFollowsDaylight() {
        #expect(SkyState(body: .sun, daylight: 1).cloudVisibility == 1)
        #expect(SkyState(body: .moon, daylight: 0).cloudVisibility == 0)
        #expect(isApproximately(SkyState(body: .sun, daylight: 0.5).cloudVisibility, 0.5))
        #expect(SkyState(body: .sun, daylight: 0.7).cloudVisibility == 1)
        #expect(SkyState(body: .moon, daylight: 0.3).cloudVisibility == 0)
    }

    @Test("空の明るさは時刻とともに少しずつ変わる")
    func daylightChangesGradually() {
        #expect(sky(9).daylight > sky(7).daylight)
        #expect(sky(21).daylight < sky(19).daylight)
    }

    private func sun(_ hour: Int, _ minute: Int = 0) -> SunPosition? {
        DaylightCycle.sun(at: TestCalendar.date(2026, 1, 1, hour, minute), calendar: TestCalendar.calendar)
    }

    @Test("太陽は日の出から日の入りの直前までだけ出ている")
    func sunExistsOnlyDuringDaytime() {
        #expect(sun(5, 59) == nil)
        #expect(sun(6) == SunPosition(progress: 0))
        #expect(sun(17, 59) != nil)
        #expect(sun(18) == nil)
    }

    @Test("太陽は正午に最も高く、窓の左から右へ動く")
    func sunMovesLeftToRight() throws {
        let sunrise = try #require(sun(6))
        let noon = try #require(sun(12))
        let evening = try #require(sun(17))
        #expect(isApproximately(sunrise.horizontal, -1))
        #expect(isApproximately(sunrise.elevation, 0))
        #expect(isApproximately(noon.horizontal, 0))
        #expect(isApproximately(noon.elevation, 1))
        #expect(evening.horizontal > 0.9)
    }
}
