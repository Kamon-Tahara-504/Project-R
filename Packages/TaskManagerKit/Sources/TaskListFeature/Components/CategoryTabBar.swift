import DesignSystem
import Domain
import SwiftUI

/// 固定の「全て」と、ユーザーが追加したカテゴリを長円のバッジで最大 2 段に並べたタブ。
/// 2 段に収まらない分は横スクロールで見せる。長押しでカテゴリを削除できる
struct CategoryTabBar: View {
    let categories: [TaskCategory]
    /// `nil` は「全て」
    @Binding var selectedID: TaskCategory.ID?
    let onAdd: () -> Void
    let onDelete: (TaskCategory) -> Void

    /// バッジの左右に確保する、ガラスの影の分の余白
    private static let shadowRoom: CGFloat = 20
    /// 追加ボタンの直径
    private static let addButtonSize: CGFloat = 48
    /// 追加ボタンの「+」を置く枠。iOS 26 のガラスのボタンはこの周りに余白を足して `addButtonSize` 前後になる
    private static let addButtonIconFrame: CGFloat = 28
    /// 最後のカテゴリを追加ボタンの左まで出すためのスクロール余白
    private static let addButtonReservedWidth: CGFloat = addButtonSize + 8
    /// バッジ同士の左右と上下の間隔
    private static let badgeSpacing: CGFloat = 8

    /// タブ全体の幅。横スクロールの中ではバッジを何段に並べるか決められないため、外側で測っておく
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                badges
                    .padding(.vertical, 4)
                    // 左端のバッジの影が切れないよう余白を内側に取り、その分を外側で詰めて見た目の位置は変えない
                    .padding(.leading, Self.shadowRoom)
                    .padding(.trailing, Self.shadowRoom + Self.addButtonReservedWidth)
            }
            // 2 段に収まっている間は横に動かないようにする
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            // ガラスの影はぼんやり広がるため、スクロール領域の上下の端で切れると四角い灰色の帯に見える。
            // 余白でスクロール領域を広げると下のタスクや上の並び替えボタンに重なって押せなくなるため、切り取りをやめる。
            // 左右は画面の外まで広げてあるので、切り取らなくても画面の外のバッジは見えない
            .scrollClipDisabled()
            // 右側も画面の端まで広げ、バッジが追加ボタンの下を通って画面の端まで流れるようにする
            .padding(.horizontal, -Self.shadowRoom)

            addCategoryButton
                .zIndex(1)
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: {
            containerWidth = $0
        }
    }

    /// 背後をスクロールするバッジが透けて見えるよう、共通のガラス背景（影のための不透明な下地を敷く）は使わない。
    /// ボタンの中に `.interactive()` なガラスを別に重ねるとタップをそちらが受け取り、ボタンが反応しなくなるため、
    /// iOS 26 では標準のガラスのボタンにする
    @ViewBuilder
    private var addCategoryButton: some View {
        let button = Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
                .frame(width: Self.addButtonIconFrame, height: Self.addButtonIconFrame)
        }
        .tint(.primary)
        .accessibilityLabel("カテゴリを追加")

        if #available(iOS 26, *) {
            button
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
        } else {
            button
                .buttonStyle(.plain)
                .frame(width: Self.addButtonSize, height: Self.addButtonSize)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    @ViewBuilder
    private var badges: some View {
        if #available(iOS 26, *) {
            // 隣り合うガラス同士が自然に馴染むよう、まとめて描画させる
            GlassEffectContainer(spacing: Self.badgeSpacing) { badgeRows }
        } else {
            badgeRows
        }
    }

    /// 最大 2 段に並べ、収まらない分は横スクロールで見せる。追加ボタンの下には並べない
    private var badgeRows: some View {
        TwoRowBadgeLayout(
            rowWidth: containerWidth - Self.addButtonReservedWidth,
            spacing: Self.badgeSpacing,
            rowSpacing: Self.badgeSpacing
        ) {
            badge(title: "全て", id: nil, color: nil)
            ForEach(categories) { category in
                badge(title: category.name, id: category.id, color: category.color)
                    .contextMenu {
                        Button("「\(category.name)」を削除", systemImage: "trash", role: .destructive) {
                            onDelete(category)
                        }
                    }
            }
        }
    }

    /// - Parameter color: `nil` は「全て」。未分類のタスクのカードに合わせ、選択中は黒（ダークモードでは白）で塗る
    private func badge(title: String, id: TaskCategory.ID?, color: CategoryColor?) -> some View {
        let isSelected = selectedID == id
        let tint = color?.color ?? .primary
        return Button {
            selectedID = id
        } label: {
            HStack(spacing: 6) {
                // 選択していないカテゴリも色で見分けられるよう、名前の前に色の点を付ける。
                // 選択中に点を消すとバッジの幅が変わって並びがずれるため、地の色の上で見える文字色で残す
                if let color {
                    Circle()
                        .fill(isSelected ? color.foregroundOnFill : color.color)
                        .frame(width: 8, height: 8)
                }
                // 選択で太字になっても幅が変わらないよう、太字の幅を確保する。
                // 幅が変わると 2 段の振り分けが変わり、選んだだけでバッジの段が入れ替わってしまう
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .hidden()
                    .overlay {
                        Text(title)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    }
            }
            // 「全て」の地の色は黒と白が入れ替わるため、文字は画面の背景色にして常に反対の色にする
            .foregroundStyle(isSelected ? (color?.foregroundOnFill ?? Color(.systemBackground)) : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassBackground(in: Capsule(), tint: isSelected ? tint : nil)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selectedID: TaskCategory.ID?
    CategoryTabBar(
        categories: [
            TaskCategory(name: "学校課題", sortOrder: 0, color: .orange),
            TaskCategory(name: "自主制作", sortOrder: 1, color: .purple),
            TaskCategory(name: "コンテスト", sortOrder: 2, color: .green),
        ],
        selectedID: $selectedID,
        onAdd: {},
        onDelete: { _ in }
    )
    .padding()
}
