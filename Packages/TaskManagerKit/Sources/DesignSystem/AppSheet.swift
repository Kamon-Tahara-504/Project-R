import SwiftUI

/// ボトムシートの大きさ。種類を絞り、画面ごとに大きさがばらつかないようにする
public enum AppSheetSize: Sendable {
    /// 中身の少ないシート（入力欄 1 つと選択肢だけ、など）。中身が収まる高さに固定する。
    /// キーボードが出るとその真上に押し上げられるため、中身とキーボードの間が空かない。
    /// iOS 26 では全画面より低いシートは半透明で、左右に余白の付いた浮いた見た目になる（OS の仕様）
    case compact
    /// 入力欄が多いなど中身の多いシート。画面の上端まで広がり、横幅いっぱいに表示される
    case large

    /// 「小」の高さ。カテゴリ追加のシート（名前の入力欄と 8 色の選択肢）が収まる大きさ
    private static let compactHeight: CGFloat = 330

    var detent: PresentationDetent {
        switch self {
        case .compact: .height(Self.compactHeight)
        case .large: .large
        }
    }
}

/// アプリ共通のボトムシートの枠。タイトルと「キャンセル」「確定」ボタン、シートの大きさを揃える
private struct AppSheetModifier: ViewModifier {
    let title: String
    let size: AppSheetSize
    let confirmTitle: String
    let canConfirm: Bool
    /// UI テストから確定ボタンを探すための識別子
    let confirmAccessibilityIdentifier: String?
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(confirmTitle, action: onConfirm)
                            .disabled(!canConfirm)
                            .accessibilityIdentifier(confirmAccessibilityIdentifier ?? "")
                    }
                }
        }
        .presentationDetents([size.detent])
    }
}

extension View {
    /// シートの中身を、アプリ共通のボトムシートの枠に入れる。
    ///
    /// 「キャンセル」はシートを閉じる。確定時に閉じるかどうかは、保存の成否などで変わるため呼び出し側で決める
    public func appSheet(
        title: String,
        size: AppSheetSize,
        confirmTitle: String,
        canConfirm: Bool = true,
        confirmAccessibilityIdentifier: String? = nil,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            AppSheetModifier(
                title: title,
                size: size,
                confirmTitle: confirmTitle,
                canConfirm: canConfirm,
                confirmAccessibilityIdentifier: confirmAccessibilityIdentifier,
                onConfirm: onConfirm
            )
        )
    }
}

#Preview("小") {
    Color.clear.sheet(isPresented: .constant(true)) {
        DatePicker("時刻", selection: .constant(.now), displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .appSheet(title: "開始", size: .compact, confirmTitle: "決定") {}
    }
}

#Preview("大") {
    Color.clear.sheet(isPresented: .constant(true)) {
        Form { TextField("タイトル", text: .constant("")) }
            .appSheet(title: "タスクを追加", size: .large, confirmTitle: "保存") {}
    }
}
