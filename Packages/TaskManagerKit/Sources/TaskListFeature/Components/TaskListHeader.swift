import DesignSystem
import SwiftUI

/// タスク画面の見出し。共通の見出しに、件数と現在の並び順のボタンを載せる
struct TaskListHeader: View {
    /// 例: 「3件のタスク」
    let countText: String
    @Binding var sortOrder: TaskSortOrder

    var body: some View {
        ScreenHeader(title: "タスク", subtitle: countText, titleIdentifier: "taskListTitle") {
            Menu {
                Picker("並び替え", selection: $sortOrder) {
                    ForEach(TaskSortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
            } label: {
                Label(sortOrder.title, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 40)
                    .glassBackground(in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("並び替え、現在は\(sortOrder.title)")
        }
    }
}

#Preview {
    @Previewable @State var sortOrder = TaskSortOrder.dueDate
    TaskListHeader(countText: "3件のタスク", sortOrder: $sortOrder)
        .padding()
}
