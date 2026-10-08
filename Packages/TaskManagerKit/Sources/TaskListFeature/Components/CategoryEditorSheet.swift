import DesignSystem
import Domain
import SwiftUI

/// カテゴリの名前とカテゴリカラーを入力して追加するシート
struct CategoryEditorSheet: View {
    let onAdd: (String, CategoryColor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var color: CategoryColor = .blue
    @FocusState private var isNameFocused: Bool

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            TextField("カテゴリ名", text: $name)
                .focused($isNameFocused)
                .accessibilityIdentifier("categoryNameField")
            Section("カテゴリカラー") {
                ColorPalette(selection: $color)
            }
        }
        // 中身が少なく、画面上端まで広げるとキーボードとの間が大きく空くため、中身が収まる高さにする
        .appSheet(
            title: "カテゴリを追加",
            size: .compact,
            confirmTitle: "追加",
            canConfirm: canAdd,
            confirmAccessibilityIdentifier: "addCategoryButton"
        ) {
            onAdd(name, color)
            dismiss()
        }
        // 開いてすぐ名前を入力できるよう、キーボードも一緒に出す
        .onAppear { isNameFocused = true }
    }
}

/// 用意した色を丸で並べ、1つ選ばせる
private struct ColorPalette: View {
    @Binding var selection: CategoryColor

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(CategoryColor.allCases, id: \.self) { candidate in
                Button {
                    selection = candidate
                } label: {
                    Circle()
                        .fill(candidate.color)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if candidate == selection {
                                Image(systemName: "checkmark")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(candidate.accessibilityName)
                .accessibilityAddTraits(candidate == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    CategoryEditorSheet { _, _ in }
}
