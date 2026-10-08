import CoreGraphics
import SwiftUI
import Testing

@testable import HomeFeature

struct CeilingBeamAlignmentTests {
    /// イラストと同じ縦横比の画面
    private let size = CGSize(width: 1320, height: 2868)
    private var beamY: CGFloat { CeilingBeamAlignment.beamCenterY * size.height }

    @Test("日付の行の位置が分からない間は拡大しない")
    func noTargetKeepsIllustration() {
        #expect(CeilingBeamAlignment.make(containerSize: size, targetY: nil) == .none)
    }

    @Test("梁を上げるときは下端を基準に拡大し、梁の中心が目標の高さに来る")
    func movingBeamUpScalesFromBottom() {
        let target = beamY - 30
        let alignment = CeilingBeamAlignment.make(containerSize: size, targetY: target)

        #expect(alignment.anchor == .bottom)
        #expect(alignment.scale > 1)
        let movedBeamY = size.height - (size.height - beamY) * alignment.scale
        #expect(abs(movedBeamY - target) < 0.001)
    }

    @Test("梁を下げるときは上端を基準に拡大し、梁の中心が目標の高さに来る")
    func movingBeamDownScalesFromTop() {
        let target = beamY + 30
        let alignment = CeilingBeamAlignment.make(containerSize: size, targetY: target)

        #expect(alignment.anchor == .top)
        #expect(alignment.scale > 1)
        #expect(abs(beamY * alignment.scale - target) < 0.001)
    }
}
