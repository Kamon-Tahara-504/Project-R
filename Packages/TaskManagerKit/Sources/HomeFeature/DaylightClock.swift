import Foundation

/// 昼夜ゲージを動かす時計
public enum DaylightClock: Equatable, Sendable {
    /// 実際の時刻どおりに進む
    case realTime
    /// 実時間の `secondsPerDay` 秒で 1 日分（0:00〜24:00）が進む。ゲージの見え方を確認するデモ用
    case accelerated(secondsPerDay: TimeInterval)

    private static let secondsPerRealDay: TimeInterval = 24 * 60 * 60

    /// 時刻に合わせた表示を描き直す間隔。早送り中は分単位だと動きが見えないため、毎フレーム描き直す
    var refreshInterval: TimeInterval {
        switch self {
        case .realTime:
            return 60
        case .accelerated:
            return 1.0 / 30
        }
    }

    /// ゲージに表示させる時刻
    func date(at now: Date, calendar: Calendar) -> Date {
        switch self {
        case .realTime:
            return now
        case .accelerated(let secondsPerDay):
            let elapsed = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: secondsPerDay)
            return calendar.startOfDay(for: now).addingTimeInterval(elapsed / secondsPerDay * Self.secondsPerRealDay)
        }
    }
}
