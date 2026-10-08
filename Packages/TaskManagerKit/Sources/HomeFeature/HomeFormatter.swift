import Domain
import Foundation

/// ホームに表示する日付・時刻の文言。
///
/// デザイン案に合わせて英語表記にしているため、端末の言語設定によらず en_US で整形する。
enum HomeFormatter {
    private static let locale = Locale(identifier: "en_US_POSIX")
    /// 「9」「12」のような 12 時間表記の時
    private static let twelveHour = Date.FormatStyle.Symbol.VerbatimHour.defaultDigits(
        clock: .twelveHour,
        hourCycle: .oneBased
    )

    /// 例: 「Apr 1, 2025」
    static func dateText(_ date: Date, calendar: Calendar) -> String {
        format(date, "\(month: .abbreviated) \(day: .defaultDigits), \(year: .defaultDigits)", calendar: calendar)
    }

    /// 例: 「9:41」「18:05」。ゲージ内の狭い場所に収めるため、AM/PM の付かない 24 時間表記にする
    static func gaugeTimeText(_ date: Date, calendar: Calendar) -> String {
        format(
            date,
            "\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
            calendar: calendar
        )
    }

    /// 例: 「Mon Jun」
    static func weekdayAndMonthText(_ date: Date, calendar: Calendar) -> String {
        format(date, "\(weekday: .abbreviated) \(month: .abbreviated)", calendar: calendar)
    }

    /// 例: 「1」
    static func dayText(_ date: Date, calendar: Calendar) -> String {
        format(date, "\(day: .defaultDigits)", calendar: calendar)
    }

    /// 例: 「11:30AM-12:30PM」
    static func timeRangeText(_ schedule: TaskSchedule, calendar: Calendar) -> String {
        "\(compactTime(schedule.start, calendar: calendar))-\(compactTime(schedule.end, calendar: calendar))"
    }

    private static func compactTime(_ date: Date, calendar: Calendar) -> String {
        format(
            date,
            "\(hour: twelveHour):\(minute: .twoDigits)\(dayPeriod: .standard(.abbreviated))",
            calendar: calendar
        )
    }

    private static func format(_ date: Date, _ format: Date.FormatString, calendar: Calendar) -> String {
        date.formatted(
            Date.VerbatimFormatStyle(format: format, locale: locale, timeZone: calendar.timeZone, calendar: calendar)
        )
    }
}
