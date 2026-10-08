import SwiftUI

/// ホームの背景。部屋のイラストに、時刻に合わせた光の色・人物の影・明かりを重ねる
struct RoomBackground: View {
    let daylightClock: DaylightClock
    /// 天井の梁の中心を合わせる、画面の上端からの高さ（日付の行の中心）。`nil` ならイラストをそのまま敷く
    var beamTargetY: CGFloat?
    private let calendar = Calendar.current

    var body: some View {
        // イラストに直接 ignoresSafeArea を掛けると、安全領域の内側（ホームの中身の大きさ）に合わせて拡大され、
        // はみ出した分が中身を基準に上下へ振り分けられる。上下の余白は異なるため、画面の下端に隙間ができる。
        // どんな大きさも受け入れる透明な土台にイラストを重ね、土台ごと画面いっぱいに広げる
        Color.clear
            .overlay {
                GeometryReader { proxy in
                    let alignment = CeilingBeamAlignment.make(containerSize: proxy.size, targetY: beamTargetY)
                    TimelineView(.periodic(from: .now, by: daylightClock.refreshInterval)) { context in
                        room(at: daylightClock.date(at: context.date, calendar: calendar))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            // 影や明かりもイラストと一緒に動くよう、重ねたものごと拡大する
                            .scaleEffect(alignment.scale, anchor: alignment.anchor)
                    }
                }
            }
            .ignoresSafeArea()
    }

    private func room(at date: Date) -> some View {
        let tint = RoomTintCycle.tint(at: date, calendar: calendar)
        let sun = DaylightCycle.sun(at: date, calendar: calendar)
        let daylight = DaylightCycle.sky(at: date, calendar: calendar).daylight

        // 影や明かりをイラスト上の決まった位置に置くため、画面ではなく拡大後のイラストを基準に重ねる
        return RoomIllustration()
            .overlay {
                if let sun {
                    PersonShadow(sun: sun)
                }
            }
            .colorMultiply(tint.color)
            .overlay { SunlitHighlights(color: tint.color, strength: SunlitHighlights.strength(sun: sun)) }
            .overlay(Color.black.opacity(tint.darkness))
            // 暗さを重ねたあとに描き、夜の部屋の中でスタンドの明かりだけが浮かぶようにする
            .overlay { LanternGlow(strength: LanternGlow.strength(daylight: daylight)) }
    }
}

/// 部屋のイラスト。影や光をこの上に重ねるため、重ねる側でも同じ大きさで描けるよう切り出している
private struct RoomIllustration: View {
    var body: some View {
        Image("HomeBackground", bundle: .module)
            .resizable()
            .scaledToFill()
    }
}

/// イラスト内の位置（イラストの幅・高さに対する割合）
private enum RoomLayout {
    /// 椅子に座った人物の足元
    static let personFeet = UnitPoint(x: 0.63, y: 0.455)
    /// 机の上のランタン
    static let lantern = UnitPoint(x: 0.603, y: 0.313)
}

/// 人物の足元から、日差しと反対側へ伸びる影
private struct PersonShadow: View {
    let sun: SunPosition

    /// 影の太さ（イラストの幅に対する割合）
    private let thickness: CGFloat = 0.085
    /// 正午の影の長さ（イラストの高さに対する割合）
    private let shortestLength: CGFloat = 0.05
    /// 日の出・日の入りに向けて伸びる長さ（イラストの高さに対する割合）
    private let extraLength: CGFloat = 0.2
    /// 日差しが真横から差すときに、影が横へ倒れる角度（度）
    private let maxTiltDegrees: Double = 55

    var body: some View {
        GeometryReader { proxy in
            let length = (shortestLength + (1 - sun.elevation) * extraLength) * proxy.size.height
            Ellipse()
                .fill(.black)
                .frame(width: thickness * proxy.size.width, height: length)
                .blur(radius: 4)
                // 窓は人物の奥にあるため影は手前（画面下）へ伸び、太陽と左右反対側へ倒れる
                .rotationEffect(.degrees(maxTiltDegrees * sun.horizontal), anchor: .top)
                .position(
                    x: RoomLayout.personFeet.x * proxy.size.width,
                    // 足元から影が始まって見えるよう、少し上に重ねる
                    y: RoomLayout.personFeet.y * proxy.size.height + length * 0.4
                )
                .opacity(opacity)
        }
        .allowsHitTesting(false)
    }

    /// 日の出・日の入りの瞬間に影が急に現れたり消えたりしないよう、地平線近くでは薄くする
    private var opacity: Double {
        0.45 * min(sun.elevation * 4, 1)
    }
}

/// 絵の中の明るい部分（窓や床の日だまり）を、日差しの色で光らせる。
///
/// 光の形を別に描かなくて済むよう、イラスト自体の明るさから光らせる範囲を作っている。
private struct SunlitHighlights: View {
    let color: Color
    /// 光の強さ（0〜1）
    let strength: Double

    var body: some View {
        color
            .mask {
                // 壁などの中間の灰色は外し、白に近い部分だけを残す
                RoomIllustration()
                    .brightness(-0.3)
                    .contrast(3)
                    .luminanceToAlpha()
            }
            .blur(radius: 6)
            .blendMode(.screen)
            .opacity(strength)
            .allowsHitTesting(false)
    }

    /// 日中だけ光らせる。日の出・日の入りの瞬間に急に切り替わらないよう、地平線近くでは弱める
    static func strength(sun: SunPosition?) -> Double {
        guard let sun else { return 0 }
        return 0.5 * min(sun.elevation * 3, 1)
    }
}

/// 夜に灯るランタンの明かり
private struct LanternGlow: View {
    /// 明かりの強さ（0〜1）
    let strength: Double

    private static let color = Color(red: 1.00, green: 0.75, blue: 0.40)

    var body: some View {
        GeometryReader { proxy in
            RadialGradient(
                colors: [Self.color.opacity(0.8), Self.color.opacity(0)],
                center: RoomLayout.lantern,
                startRadius: 0,
                endRadius: proxy.size.width * 0.22
            )
            .blendMode(.screen)
            .opacity(strength)
        }
        .allowsHitTesting(false)
    }

    /// 夕暮れに少しずつ灯り始め、夜明けに少しずつ消える
    static func strength(daylight: Double) -> Double {
        min(max((0.45 - daylight) / 0.2, 0), 1)
    }
}

#Preview("30 秒で 1 日") {
    RoomBackground(daylightClock: .accelerated(secondsPerDay: 30))
}
