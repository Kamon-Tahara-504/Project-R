import SwiftUI

/// ゲージの背景で左へ流れていく飾り。日中は小さな雲、夜は点滅する十字の星
struct SkyDecoration: View {
    /// 雲の見え具合（0〜1）。星は残りの割合で表示する
    let cloudVisibility: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            Canvas { canvas, size in
                let time = context.date.timeIntervalSinceReferenceDate
                if cloudVisibility > 0 {
                    drawClouds(in: &canvas, size: size, time: time)
                }
                if cloudVisibility < 1 {
                    drawStars(in: &canvas, size: size, time: time)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func drawClouds(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for cloud in Self.clouds {
            let center = CGPoint(
                x: driftedX(
                    base: cloud.relativeX, itemWidth: cloud.width, speed: Self.cloudSpeed, time: time, width: size.width
                ),
                y: cloud.relativeY * size.height
            )
            let opacity = 0.6 * cloudVisibility * centerFade(centerX: center.x, width: size.width)
            canvas.fill(cloudPath(center: center, width: cloud.width), with: .color(.white.opacity(opacity)))
        }
    }

    /// 中央に並ぶアイコンと時刻に雲が重なると読みにくいため、中央に近づくほど雲を透明にする（0〜1）
    private func centerFade(centerX: CGFloat, width: CGFloat) -> Double {
        let distanceFromCenter = abs(centerX - width / 2)
        return Double(min(max((distanceFromCenter - Self.cloudClearHalfWidth) / Self.cloudFadeLength, 0), 1))
    }

    private func drawStars(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for star in Self.stars {
            let center = CGPoint(
                x: driftedX(
                    base: star.relativeX, itemWidth: star.size, speed: Self.starSpeed, time: time, width: size.width
                ),
                y: star.relativeY * size.height
            )
            // 星ごとに周期と位相をずらし、一斉に瞬かないようにする
            let twinkle = 0.5 + 0.5 * sin(time * 2 * .pi / star.period + star.phase)
            let opacity = (0.2 + 0.8 * twinkle) * (1 - cloudVisibility)
            canvas.fill(starPath(center: center, size: star.size), with: .color(.white.opacity(opacity)))
        }
    }

    /// 時間とともに左へずらした x 座標。左端から出たら右端から戻ってくる
    private func driftedX(
        base: CGFloat,
        itemWidth: CGFloat,
        speed: Double,
        time: TimeInterval,
        width: CGFloat
    ) -> CGFloat {
        // 端で急に消えたり現れたりしないよう、要素の幅だけ外側まで移動させてから折り返す
        let span = width + itemWidth
        let shifted = (Double(base * span) - time * speed).truncatingRemainder(dividingBy: Double(span))
        let wrapped = shifted < 0 ? shifted + Double(span) : shifted
        return CGFloat(wrapped) - itemWidth / 2
    }

    private func cloudPath(center: CGPoint, width: CGFloat) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - width / 2, y: center.y, width: width, height: width * 0.35))
        path.addEllipse(
            in: CGRect(x: center.x - width * 0.3, y: center.y - width * 0.25, width: width * 0.45, height: width * 0.45)
        )
        path.addEllipse(
            in: CGRect(x: center.x, y: center.y - width * 0.15, width: width * 0.35, height: width * 0.35)
        )
        return path
    }

    /// 上下左右に尖った 4 本の光を持つ十字の星
    private func starPath(center: CGPoint, size: CGFloat) -> Path {
        let radius = size / 2
        let pinch = radius * 0.18
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addQuadCurve(
            to: CGPoint(x: center.x + radius, y: center.y),
            control: CGPoint(x: center.x + pinch, y: center.y - pinch)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + radius),
            control: CGPoint(x: center.x + pinch, y: center.y + pinch)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - radius, y: center.y),
            control: CGPoint(x: center.x - pinch, y: center.y + pinch)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - radius),
            control: CGPoint(x: center.x - pinch, y: center.y - pinch)
        )
        path.closeSubpath()
        return path
    }
}

extension SkyDecoration {
    /// relativeX・relativeY はゲージ内の相対位置（0〜1）
    private struct Cloud {
        let relativeX: CGFloat
        let relativeY: CGFloat
        let width: CGFloat
    }

    /// relativeX・relativeY はゲージ内の相対位置（0〜1）。period は瞬きの周期（秒）
    private struct Star {
        let relativeX: CGFloat
        let relativeY: CGFloat
        let size: CGFloat
        let period: Double
        let phase: Double
    }

    /// 1 秒あたりに左へ流れる距離（pt）
    private static let cloudSpeed: Double = 6
    private static let starSpeed: Double = 4

    /// 中央からこの距離（pt）以内では雲を完全に消す。
    /// 4 桁の時刻（例: 16:13）でも雲の端が文字に掛からないよう、アイコンと時刻の幅の半分に雲の半幅を足した値にしている
    private static let cloudClearHalfWidth: CGFloat = 36
    /// 雲を消す範囲の外側で、透明から元の濃さに戻るまでの距離（pt）
    private static let cloudFadeLength: CGFloat = 10

    // まばらに見えるよう数を絞り、間隔を空けている
    private static let clouds = [
        Cloud(relativeX: 0.10, relativeY: 0.40, width: 14),
        Cloud(relativeX: 0.65, relativeY: 0.55, width: 12),
    ]

    private static let stars = [
        Star(relativeX: 0.05, relativeY: 0.30, size: 6, period: 1.8, phase: 0),
        Star(relativeX: 0.22, relativeY: 0.70, size: 5, period: 2.4, phase: 1.2),
        Star(relativeX: 0.40, relativeY: 0.25, size: 4, period: 1.5, phase: 2.5),
        Star(relativeX: 0.58, relativeY: 0.75, size: 6, period: 2.1, phase: 0.7),
        Star(relativeX: 0.75, relativeY: 0.35, size: 5, period: 2.7, phase: 3.4),
        Star(relativeX: 0.90, relativeY: 0.65, size: 4, period: 1.9, phase: 4.6),
    ]
}
