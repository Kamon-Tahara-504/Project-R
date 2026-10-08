import Domain
import SwiftUI

/// 今日のタスクを時間付きで並べるカード
struct TodayTaskCard: View {
    struct Entry: Identifiable {
        let task: TaskItem
        /// 例: 「11:30AM-12:30PM」
        let timeRangeText: String

        var id: TaskItem.ID { task.id }
    }

    let entries: [Entry]
    let onSelect: (TaskItem) -> Void

    var body: some View {
        Group {
            if entries.isEmpty {
                Text("今日の予定はありません")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(entries) { entry in
                            row(entry)
                        }
                    }
                    .padding()
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxHeight: 280)
        .fixedSize(horizontal: false, vertical: entries.count <= 3)
        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ entry: Entry) -> some View {
        Button {
            onSelect(entry.task)
        } label: {
            HStack(spacing: 8) {
                Capsule()
                    .fill(.white)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.timeRangeText)
                        .font(.subheadline.weight(.semibold))
                    Text(entry.task.title)
                        .font(.subheadline)
                        .strikethrough(entry.task.isCompleted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayTaskCard(
        entries: [
            .init(task: TaskItem(title: "ジャンルを問わず"), timeRangeText: "11:30AM-12:30PM"),
            .init(task: TaskItem(title: "期限の近い ToDo の上位5つを表示"), timeRangeText: "1:00PM-2:00PM"),
        ],
        onSelect: { _ in }
    )
    .padding()
    .background(.gray)
}
