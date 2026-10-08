import Foundation

/// 実行環境のタイムゾーンに左右されないよう、テストではこのカレンダーで日時を作る
public enum TestCalendar {
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        return calendar
    }()

    public static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        guard let date = calendar.date(from: components) else {
            preconditionFailure("不正な日時です: \(components)")
        }
        return date
    }
}
