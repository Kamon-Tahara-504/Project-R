import Domain
import SwiftUI

/// 部屋全体の色味。白黒のイラストに重ねて、時間帯の光の色を表現する
struct RoomTint: Equatable {
    /// イラストに掛け合わせる光の色。白に近いほど元の絵のままになる
    let color: Color
    /// 上から重ねる暗さ（0〜1）。昼でも少し暗くするのは、白い文字を読みやすくするため
    let darkness: Double
    /// 昼夜ゲージの背景に映す空の色。
    ///
    /// 朝焼け・夕焼けで部屋とゲージの色がずれないよう、部屋の光と同じ節目で一緒に移り変わらせる。
    /// 上に白い文字を載せるため、部屋の光の色より濃いめにしている
    let skyColor: Color
}

/// 時刻から部屋の色味を決める
enum RoomTintCycle {
    /// 色味の節目。節目と節目のあいだは補間して、少しずつ色が移るようにする
    private static let keyframes: [(time: TimeOfDay, tint: RoomTint)] = [
        (TimeOfDay(hour: 4, minute: 30), night),
        // 夜明け前: 紫がかった空
        (
            TimeOfDay(hour: 5, minute: 30),
            RoomTint(
                color: Color(red: 0.80, green: 0.68, blue: 0.85), darkness: 0.30,
                skyColor: Color(red: 0.42, green: 0.35, blue: 0.62)
            )
        ),
        // 朝焼け
        (
            TimeOfDay(hour: 6, minute: 30),
            RoomTint(
                color: Color(red: 1.00, green: 0.78, blue: 0.60), darkness: 0.18,
                skyColor: Color(red: 0.95, green: 0.62, blue: 0.45)
            )
        ),
        (
            TimeOfDay(hour: 9, minute: 0),
            RoomTint(
                color: Color(red: 1.00, green: 0.97, blue: 0.90), darkness: 0.10,
                skyColor: Color(red: 0.50, green: 0.78, blue: 0.98)
            )
        ),
        (
            TimeOfDay(hour: 12, minute: 0),
            RoomTint(
                color: Color(red: 1.00, green: 1.00, blue: 0.97), darkness: 0.10,
                skyColor: Color(red: 0.55, green: 0.83, blue: 1.00)
            )
        ),
        (
            TimeOfDay(hour: 15, minute: 0),
            RoomTint(
                color: Color(red: 1.00, green: 0.94, blue: 0.82), darkness: 0.12,
                skyColor: Color(red: 0.58, green: 0.80, blue: 0.96)
            )
        ),
        // 夕方: 橙色の空
        (
            TimeOfDay(hour: 17, minute: 0),
            RoomTint(
                color: Color(red: 1.00, green: 0.68, blue: 0.42), darkness: 0.15,
                skyColor: Color(red: 0.98, green: 0.62, blue: 0.35)
            )
        ),
        // 日の入り: 赤みがかった空
        (
            TimeOfDay(hour: 18, minute: 0),
            RoomTint(
                color: Color(red: 0.90, green: 0.55, blue: 0.55), darkness: 0.22,
                skyColor: Color(red: 0.90, green: 0.45, blue: 0.45)
            )
        ),
        // 薄暮: 紫がかった空
        (
            TimeOfDay(hour: 19, minute: 0),
            RoomTint(
                color: Color(red: 0.55, green: 0.52, blue: 0.80), darkness: 0.38,
                skyColor: Color(red: 0.40, green: 0.32, blue: 0.62)
            )
        ),
        (TimeOfDay(hour: 20, minute: 0), night),
    ]

    /// 夜: 青みがかった暗い部屋と、深い青の空
    private static let night = RoomTint(
        color: Color(red: 0.45, green: 0.52, blue: 0.80), darkness: 0.45,
        skyColor: Color(red: 0.10, green: 0.15, blue: 0.38)
    )

    private static let minutesPerDay = 24 * 60

    static func tint(at date: Date, calendar: Calendar) -> RoomTint {
        let now = TimeOfDay(date: date, calendar: calendar)
        // 最初の節目より前（深夜）は、前日の最後の節目から続いているものとして扱う
        let index =
            keyframes.lastIndex { $0.time.minutesSinceMidnight <= now.minutesSinceMidnight } ?? keyframes.count - 1
        let previous = keyframes[index]
        let next = keyframes[(index + 1) % keyframes.count]

        let span = minutes(from: previous.time, to: next.time)
        let elapsed = minutes(from: previous.time, to: now)
        let fraction = span == 0 ? 0 : Double(elapsed) / Double(span)
        return RoomTint(
            color: previous.tint.color.mix(with: next.tint.color, by: fraction),
            darkness: previous.tint.darkness + (next.tint.darkness - previous.tint.darkness) * fraction,
            skyColor: previous.tint.skyColor.mix(with: next.tint.skyColor, by: fraction)
        )
    }

    /// `start` から `end` まで進むのにかかる分数。日をまたぐ場合も正の値を返す
    private static func minutes(from start: TimeOfDay, to end: TimeOfDay) -> Int {
        (end.minutesSinceMidnight - start.minutesSinceMidnight + minutesPerDay) % minutesPerDay
    }
}
