import Domain
import Foundation

/// ゲージに映す空の状態
struct SkyState: Equatable {
    enum Body: Equatable {
        case sun
        case moon
    }

    /// 表示する天体（日中は太陽、夜間は月）
    let body: Body
    /// 空の明るさ。真夜中を 0、正午を 1 とし、アイコンの色や雲・星の入れ替わりに使う
    let daylight: Double

    /// 背景の雲の見え具合（0〜1）。星は残りの割合で表示する。
    ///
    /// 太陽と月は日の出・日の入りの瞬間に切り替わるが、飾りは急に入れ替わると目立つため、その前後で少しずつ入れ替える。
    var cloudVisibility: Double {
        min(max((daylight - 0.4) / 0.2, 0), 1)
    }
}

/// 部屋に差し込む日差しの元になる太陽の位置
struct SunPosition: Equatable {
    /// 日の出を 0、日の入りを 1 とした太陽の進み具合
    let progress: Double

    /// 太陽の高さ。地平線で 0、正午に 1。影の長さと濃さに使う
    var elevation: Double {
        sin(progress * .pi)
    }

    /// 窓越しに見た太陽の左右の位置。日の出で -1（左端）、正午に 0、日の入りで 1（右端）。
    ///
    /// 部屋の向きは決まっていないため、朝日が窓の左側から差し込む部屋という想定にしている。
    var horizontal: Double {
        -cos(progress * .pi)
    }
}

/// 時刻から、ゲージに映す空の状態と太陽の位置を決める
enum DaylightCycle {
    // 位置情報の許可を求めずに済むよう、実際の日の出・日の入りではなく固定の時刻で昼夜を区切る
    static let sunrise = TimeOfDay(hour: 6, minute: 0)
    static let sunset = TimeOfDay(hour: 18, minute: 0)

    private static let minutesPerDay = 24 * 60

    static func sky(at date: Date, calendar: Calendar) -> SkyState {
        let now = TimeOfDay(date: date, calendar: calendar).minutesSinceMidnight
        let isDaytime = (sunrise.minutesSinceMidnight..<sunset.minutesSinceMidnight).contains(now)
        return SkyState(body: isDaytime ? .sun : .moon, daylight: daylight(atMinutes: now))
    }

    /// 日の出から日の入りまでの太陽の位置。夜間は日差しがないため nil を返す
    static func sun(at date: Date, calendar: Calendar) -> SunPosition? {
        let now = TimeOfDay(date: date, calendar: calendar).minutesSinceMidnight
        let start = sunrise.minutesSinceMidnight
        let end = sunset.minutesSinceMidnight
        guard (start..<end).contains(now) else { return nil }
        return SunPosition(progress: Double(now - start) / Double(end - start))
    }

    /// 日の出と日の入りの中間を正午として、1 日周期の余弦で明るさを求める。
    ///
    /// 2 色の切り替えではなく常に少しずつ色が変わるようにするため、直線ではなく滑らかな曲線にしている。
    private static func daylight(atMinutes minutes: Int) -> Double {
        let solarNoon = Double(sunrise.minutesSinceMidnight + sunset.minutesSinceMidnight) / 2
        let phase = (Double(minutes) - solarNoon) / Double(minutesPerDay) * 2 * .pi
        return (1 + cos(phase)) / 2
    }
}
