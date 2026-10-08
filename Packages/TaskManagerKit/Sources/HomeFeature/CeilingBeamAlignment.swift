import CoreGraphics
import SwiftUI

/// 背景のイラストを少し拡大して、天井の梁（暗い横帯）の中心を日付の行の高さに合わせる。
///
/// 梁の画面上の高さは端末の縦横比で、日付の行の高さは安全領域で変わり、両者は端末ごとにずれ方が違う。
/// 固定の量でずらすと端末によって合わなくなるため、画面の大きさと日付の行の位置から毎回求める。
/// ずらすだけだと画面の端に隙間ができるため、梁と反対側の画面の端を基準に拡大して動かす
struct CeilingBeamAlignment: Equatable {
    /// イラストの縦横比（幅 / 高さ）。home_background.png（1320 × 2868）に合わせる
    static let illustrationAspectRatio: CGFloat = 1320 / 2868
    /// 梁の中心の高さ（イラストの高さに対する割合）
    static let beamCenterY: CGFloat = 0.1137

    let scale: CGFloat
    let anchor: UnitPoint

    static let none = CeilingBeamAlignment(scale: 1, anchor: .center)

    /// - Parameters:
    ///   - containerSize: イラストを敷き詰める領域（画面全体）の大きさ
    ///   - targetY: 梁の中心を合わせたい、領域の上端からの高さ。まだ測れていなければ `nil`
    static func make(containerSize: CGSize, targetY: CGFloat?) -> CeilingBeamAlignment {
        guard let targetY, containerSize.width > 0, containerSize.height > 0 else { return .none }

        let height = containerSize.height
        // scaledToFill で敷き詰めたときのイラストの高さと、梁の中心の高さ
        let illustrationHeight = max(height, containerSize.width / illustrationAspectRatio)
        let top = (height - illustrationHeight) / 2
        let beamY = top + beamCenterY * illustrationHeight

        guard beamY > 0, beamY < height, targetY > 0, targetY < height else { return .none }
        if targetY < beamY {
            // 梁を上げる。下端を基準に拡大すると、下端からの距離が拡大率の分だけ伸びる
            return CeilingBeamAlignment(scale: (height - targetY) / (height - beamY), anchor: .bottom)
        }
        // 梁を下げる。上端を基準に拡大すると、上端からの距離が拡大率の分だけ伸びる
        return CeilingBeamAlignment(scale: targetY / beamY, anchor: .top)
    }
}
