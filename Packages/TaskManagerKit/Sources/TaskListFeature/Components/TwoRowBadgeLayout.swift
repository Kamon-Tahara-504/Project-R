import SwiftUI

/// バッジを最大 2 段に並べるレイアウト。順番は崩さずに、前から 1 段目・2 段目へ詰める。
///
/// - 1 段に収まるなら 1 段にする。
/// - 2 段に収まるなら、1 段目を幅いっぱいまで埋めて残りを 2 段目にする。
/// - 2 段にも収まらないなら、2 段の幅がなるべく揃うところで分け、はみ出た分は横スクロールで見せる。
///
/// 横スクロールの中では幅の提案がない（無限）ため、1 段に並べられる幅は外から渡す
struct TwoRowBadgeLayout: Layout {
    /// 1 段に並べられる幅。0 以下なら（画面の幅がまだ分からない間は）1 段にする
    var rowWidth: CGFloat
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let rows = rows(for: sizes.map(\.width))
        let widestRow = rows.map { width(of: $0, in: sizes) }.max() ?? 0
        let rowHeights = rows.map { height(of: $0, in: sizes) }
        return CGSize(
            width: widestRow,
            height: rowHeights.reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0))
        )
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var rowTop = bounds.minY
        for row in rows(for: sizes.map(\.width)) {
            let rowHeight = height(of: row, in: sizes)
            var leading = bounds.minX
            for index in row {
                subviews[index].place(
                    at: CGPoint(x: leading, y: rowTop + rowHeight / 2),
                    anchor: .leading,
                    proposal: ProposedViewSize(sizes[index])
                )
                leading += sizes[index].width + spacing
            }
            rowTop += rowHeight + rowSpacing
        }
    }

    /// 各段に並べるバッジの範囲
    private func rows(for widths: [CGFloat]) -> [Range<Int>] {
        let count = widths.count
        guard count > 1, rowWidth > 0, totalWidth(widths[...]) > rowWidth else {
            return count == 0 ? [] : [0..<count]
        }

        // 1 段目に入るだけ入れる（最低 1 つ）
        var split = 1
        while split < count, totalWidth(widths[0...split]) <= rowWidth {
            split += 1
        }
        if totalWidth(widths[split...]) <= rowWidth {
            return [0..<split, split..<count]
        }

        // 2 段にも収まらないときは、長い方の段が最も短くなるところで分ける
        let balancedSplit =
            (1..<count).min { lhs, rhs in
                longerRowWidth(splittingAt: lhs, widths) < longerRowWidth(splittingAt: rhs, widths)
            } ?? split
        return [0..<balancedSplit, balancedSplit..<count]
    }

    private func longerRowWidth(splittingAt split: Int, _ widths: [CGFloat]) -> CGFloat {
        max(totalWidth(widths[..<split]), totalWidth(widths[split...]))
    }

    /// 間隔を含めた、並べたときの幅
    private func totalWidth(_ widths: ArraySlice<CGFloat>) -> CGFloat {
        widths.reduce(0, +) + spacing * CGFloat(max(widths.count - 1, 0))
    }

    private func width(of row: Range<Int>, in sizes: [CGSize]) -> CGFloat {
        totalWidth(sizes[row].map(\.width)[...])
    }

    private func height(of row: Range<Int>, in sizes: [CGSize]) -> CGFloat {
        sizes[row].map(\.height).max() ?? 0
    }
}
