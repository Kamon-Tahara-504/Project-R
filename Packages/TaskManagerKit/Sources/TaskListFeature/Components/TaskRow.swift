import DesignSystem
import Domain
import SwiftUI

/// タスク画面の1行。表示用の文言は ViewModel で作ったものを受け取り、ここでは見た目だけを担当する
struct TaskRow: View {
    let task: TaskItem
    let dueDateText: String?
    let remainingDaysText: String?
    let isDueSoon: Bool
    /// 属するカテゴリの色。未分類のタスクは `nil` で、背景に色を付けず縦線とボタンを黒にした白黒のカードにする
    let categoryColor: Color?
    let onToggle: () -> Void

    private static let stripeWidth: CGFloat = 4
    /// カードの縁から縦線までの距離
    private static let stripeInset: CGFloat = 8
    /// ガラスに重ねる色の濃さ。濃くすると文字が読みにくくなるため、うっすら色が分かる程度にする
    private static let tintOpacity: Double = 0.15

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    // カードの色と揃え、どのカテゴリのタスクかをボタンでも分かるようにする
                    .foregroundStyle(categoryColor ?? .primary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isCompleted ? "未完了に戻す" : "完了にする")

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    Spacer()
                    if let remainingDaysText {
                        Text(remainingDaysText)
                            .font(.caption2)
                            .foregroundStyle(isDueSoon ? .red : .secondary)
                    }
                }
                if let dueDateText {
                    Text(dueDateText)
                        .font(.caption2)
                        .foregroundStyle(detailAccent)
                }
                if let url = task.url {
                    Link(url.absoluteString, destination: url)
                        .font(.caption2)
                        .lineLimit(1)
                        .buttonStyle(.borderless)
                        .tint(detailAccent)
                }
                if !task.memo.isEmpty {
                    Text(task.memo)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        // 縦線とチェックボタンが重ならないよう、縦線の分だけ中身を右へ寄せる
        .padding(.leading, Self.stripeInset)
        // 縦線はガラスの上に描くため、ガラスを掛ける前に中身として重ねる
        .overlay(alignment: .leading) {
            Capsule()
                // `.primary` で塗るとガラスの上で薄い灰色に変わるため、システムの文字色で黒（ダークモードでは白）にする
                .fill(categoryColor ?? Color(.label))
                .frame(width: Self.stripeWidth)
                .padding(.vertical, 10)
                .padding(.leading, Self.stripeInset)
                .allowsHitTesting(false)
        }
        .glassBackground(
            in: RoundedRectangle(cornerRadius: 18, style: .continuous),
            tint: categoryColor?.opacity(Self.tintOpacity)
        )
        .contentShape(Rectangle())
    }

    /// 締切や URL の文字色。未分類のカードは白黒にするため、青ではなく黒（ダークモードでは白）にする
    private var detailAccent: Color {
        categoryColor == nil ? .primary : .accentColor
    }
}

#Preview {
    VStack {
        TaskRow(
            task: TaskItem(title: "予定1", isCompleted: true),
            dueDateText: "1月1日(水)",
            remainingDaysText: "残り7日",
            isDueSoon: true,
            categoryColor: nil,
            onToggle: {}
        )
        TaskRow(
            task: TaskItem(title: "予定3", url: URL(string: "https://example.com"), memo: "メモ"),
            dueDateText: "1月10日(金)",
            remainingDaysText: "残り16日",
            isDueSoon: false,
            categoryColor: .orange,
            onToggle: {}
        )
    }
    .padding()
}
