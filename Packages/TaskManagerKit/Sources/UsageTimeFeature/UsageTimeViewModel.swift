import Domain
import Foundation
import Observation

/// 利用時間外に、休憩画面を挟むかどうかを判定する。
///
/// 一度「確認する」を選んだら、アプリがバックグラウンドに回るまでは再び休憩画面を出さない。
/// 確認後に画面を切り替えるたびに止められると、確認した意味がなくなるため。
@MainActor
@Observable
public final class UsageTimeViewModel {
    public private(set) var isLocked = false
    /// 休憩画面に表示する、アプリを使える時間帯（例: 「8:00〜20:00」）
    public private(set) var availableHoursText = ""

    private var isUnlockedUntilBackground = false
    private let settingsRepository: any SettingsRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        settingsRepository: any SettingsRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        self.settingsRepository = settingsRepository
        self.now = now
        self.calendar = calendar
    }

    /// 起動時とフォアグラウンド復帰時に呼ぶ
    public func evaluate() {
        let usageTime = settingsRepository.load().usageTime
        availableHoursText = "\(usageTime.start)〜\(usageTime.end)"
        isLocked = !isUnlockedUntilBackground && !usageTime.allowsAccess(at: now(), calendar: calendar)
    }

    /// 「本当にタスクを確認しますか？」で確認したときに呼ぶ
    public func unlock() {
        isUnlockedUntilBackground = true
        isLocked = false
    }

    public func didEnterBackground() {
        isUnlockedUntilBackground = false
    }
}
