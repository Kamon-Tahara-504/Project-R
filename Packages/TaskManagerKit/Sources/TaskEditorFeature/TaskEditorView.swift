import DesignSystem
import Domain
import SwiftUI

/// タスクの追加・編集シート。ホームとタスク画面の両方から開く
public struct TaskEditorView: View {
    @State private var viewModel: TaskEditorViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss
    /// 保存・削除が完了したときに呼ばれる。呼び出し元の一覧を読み込み直すために使う
    private let onFinish: () -> Void

    public init(viewModel: TaskEditorViewModel, onFinish: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    public var body: some View {
        Form {
            basicSection
            dueDateSection
            scheduleSection
            notificationSection
            detailSection
            if !viewModel.isNew {
                deleteSection
            }
        }
        .alert("エラー", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .appSheet(
            title: viewModel.isNew ? "タスクを追加" : "タスクを編集",
            size: .large,
            confirmTitle: "保存",
            canConfirm: viewModel.canSave,
            confirmAccessibilityIdentifier: "editorSaveButton"
        ) {
            Task { await finish { await viewModel.save() } }
        }
    }

    private var basicSection: some View {
        Section {
            TextField("タイトル", text: $viewModel.title)
                .accessibilityIdentifier("editorTitleField")
            Picker("カテゴリ", selection: $viewModel.categoryID) {
                Text("未分類").tag(TaskCategory.ID?.none)
                ForEach(viewModel.categories) { category in
                    Text(category.name).tag(TaskCategory.ID?.some(category.id))
                }
            }
        }
    }

    private var dueDateSection: some View {
        Section("締切") {
            Toggle("締切を設定する", isOn: $viewModel.hasDueDate)
            if viewModel.hasDueDate {
                DatePicker("締切日", selection: $viewModel.dueDate, displayedComponents: .date)
            }
        }
    }

    private var scheduleSection: some View {
        Section {
            Toggle("実施時間を設定する", isOn: $viewModel.hasSchedule)
            if viewModel.hasSchedule {
                DatePicker("開始", selection: $viewModel.scheduleStart, displayedComponents: [.date, .hourAndMinute])
                DatePicker("終了", selection: $viewModel.scheduleEnd, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("実施時間")
        } footer: {
            Text("実施日が今日のタスクはホームに表示されます")
        }
    }

    private var notificationSection: some View {
        Section("通知") {
            Toggle("通知する", isOn: $viewModel.hasNotification)
            if viewModel.hasNotification {
                DatePicker("通知日時", selection: $viewModel.notifyAt, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }

    private var detailSection: some View {
        Section("詳細") {
            TextField("URL（https://...）", text: $viewModel.urlText)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("メモ", text: $viewModel.memo, axis: .vertical)
                .lineLimit(3...)
        }
    }

    private var deleteSection: some View {
        Section {
            Button("このタスクを削除", role: .destructive) {
                isConfirmingDelete = true
            }
            .confirmationDialog("このタスクを削除しますか？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    Task { await finish { await viewModel.delete() } }
                }
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }

    /// 操作が成功したときだけシートを閉じる。失敗時はエラーを表示したまま入力を残す
    private func finish(_ operation: () async -> Bool) async {
        guard await operation() else { return }
        onFinish()
        dismiss()
    }
}
