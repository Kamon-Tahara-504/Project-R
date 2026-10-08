import Domain
import DomainTestSupport
import Foundation
import Synchronization
import Testing
import UsageTimeFeature

@MainActor
struct UsageTimeViewModelTests {
    /// テスト中に時刻を進めるための、スレッドセーフな時計
    private final class Clock: Sendable {
        private let current: Mutex<Date>

        init(_ date: Date) {
            current = Mutex(date)
        }

        var now: Date { current.withLock { $0 } }

        func set(_ date: Date) {
            current.withLock { $0 = date }
        }
    }

    private let enabledSettings = AppSettings(
        usageTime: UsageTimeSettings(
            isEnabled: true,
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 20, minute: 0)
        )
    )

    private func makeViewModel(settings: AppSettings, clock: Clock) -> UsageTimeViewModel {
        UsageTimeViewModel(
            settingsRepository: InMemorySettingsRepository(settings: settings),
            now: { clock.now },
            calendar: TestCalendar.calendar
        )
    }

    @Test("時間外ならロックし、使える時間帯を表示する")
    func locksOutsideHours() {
        let viewModel = makeViewModel(settings: enabledSettings, clock: Clock(TestCalendar.date(2026, 1, 1, 22, 0)))

        viewModel.evaluate()

        #expect(viewModel.isLocked)
        #expect(viewModel.availableHoursText == "8:00〜20:00")
    }

    @Test("時間内ならロックしない")
    func unlockedWithinHours() {
        let viewModel = makeViewModel(settings: enabledSettings, clock: Clock(TestCalendar.date(2026, 1, 1, 12, 0)))

        viewModel.evaluate()

        #expect(!viewModel.isLocked)
    }

    @Test("利用時間の制限が OFF ならロックしない")
    func disabledNeverLocks() {
        let viewModel = makeViewModel(settings: .default, clock: Clock(TestCalendar.date(2026, 1, 1, 22, 0)))

        viewModel.evaluate()

        #expect(!viewModel.isLocked)
    }

    @Test("確認して解除したら、バックグラウンドに回るまではロックしない")
    func unlockLastsUntilBackground() {
        let viewModel = makeViewModel(settings: enabledSettings, clock: Clock(TestCalendar.date(2026, 1, 1, 22, 0)))
        viewModel.evaluate()

        viewModel.unlock()
        viewModel.evaluate()
        #expect(!viewModel.isLocked)

        viewModel.didEnterBackground()
        viewModel.evaluate()
        #expect(viewModel.isLocked)
    }

    @Test("時間内に戻ってから復帰するとロックが外れる")
    func reEvaluationFollowsClock() {
        let clock = Clock(TestCalendar.date(2026, 1, 1, 7, 0))
        let viewModel = makeViewModel(settings: enabledSettings, clock: clock)
        viewModel.evaluate()
        #expect(viewModel.isLocked)

        clock.set(TestCalendar.date(2026, 1, 1, 8, 0))
        viewModel.evaluate()

        #expect(!viewModel.isLocked)
    }
}
