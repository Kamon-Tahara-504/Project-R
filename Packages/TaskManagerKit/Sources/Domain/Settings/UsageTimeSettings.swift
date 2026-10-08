import Foundation

/// 利用時間の設定。
///
/// 決めた時間外はタスクを見ずに休めるよう、アプリを開いたときに休憩画面を挟むための設定。
/// 完全に締め出すのではなく、本人が確認すれば中に入れる前提。
public struct UsageTimeSettings: Equatable, Codable, Sendable {
    public var isEnabled: Bool
    /// アプリを使える時間帯の開始
    public var start: TimeOfDay
    /// アプリを使える時間帯の終了
    public var end: TimeOfDay

    public init(isEnabled: Bool, start: TimeOfDay, end: TimeOfDay) {
        self.isEnabled = isEnabled
        self.start = start
        self.end = end
    }

    public static let `default` = UsageTimeSettings(
        isEnabled: false,
        start: TimeOfDay(hour: 8, minute: 0),
        end: TimeOfDay(hour: 20, minute: 0)
    )

    /// 指定した時刻にアプリを使ってよいかどうか。
    ///
    /// - 開始時刻ちょうどは使える、終了時刻ちょうどは使えない。
    /// - 開始が終了より遅い場合（22:00〜2:00 など）は日をまたぐ時間帯として扱う。
    /// - 開始と終了が同じ場合は時間帯を作れないため、制限しない。
    public func allowsAccess(at date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return true }
        let now = TimeOfDay(date: date, calendar: calendar).minutesSinceMidnight
        let startMinutes = start.minutesSinceMidnight
        let endMinutes = end.minutesSinceMidnight

        if startMinutes == endMinutes {
            return true
        }
        if startMinutes < endMinutes {
            return startMinutes <= now && now < endMinutes
        }
        return now >= startMinutes || now < endMinutes
    }
}
