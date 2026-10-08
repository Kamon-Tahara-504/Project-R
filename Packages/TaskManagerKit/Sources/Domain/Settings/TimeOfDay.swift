import Foundation

/// 日付を持たない時刻（例: 8:00）
public struct TimeOfDay: Equatable, Codable, Sendable, CustomStringConvertible {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    /// 0:00 からの経過分。時刻同士の比較に使う
    public var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    /// 例: 「8:00」「20:05」
    public var description: String {
        "\(hour):" + (minute < 10 ? "0\(minute)" : "\(minute)")
    }

    /// 指定した日の、この時刻の `Date` を返す
    public func date(on day: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}
