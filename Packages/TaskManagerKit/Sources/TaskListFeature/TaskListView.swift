import DesignSystem
import Domain
import SwiftUI
import TaskEditorFeature

/// タスク画面。全タスクをカテゴリごとに確認・追加できる
public struct TaskListView: View {
    @State private var viewModel: TaskListViewModel
    @State private var isAddingCategory = false

    /// 画面の左右の余白
    private static let horizontalMargin: CGFloat = 16
    /// リストの上端に確保する、カードの影の分の余白。カテゴリとの間隔（12pt）より大きくするとカテゴリに重なる
    private static let listTopShadowRoom: CGFloat = 12

    public init(viewModel: TaskListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Group {
                TaskListHeader(countText: viewModel.visibleTaskCountText, sortOrder: $viewModel.sortOrder)
                CategoryTabBar(
                    categories: viewModel.categories,
                    selectedID: $viewModel.selectedCategoryID,
                    onAdd: { isAddingCategory = true },
                    onDelete: { category in Task { await viewModel.deleteCategory(category) } }
                )
            }
            .padding(.horizontal, Self.horizontalMargin)
            // 下にあるリストの背景がカテゴリのバッジの影を覆って、影が直線で切れて見えるのを防ぐ
            .zIndex(1)
            // リストは画面の端まで広げ、余白は行の内側で取る。リストの端でカードの影が切れないようにするため
            taskList
        }
        .background { ScreenBackground() }
        .task { await viewModel.load() }
        .sheet(item: $viewModel.editor) { editor in
            TaskEditorView(viewModel: editor) {
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: $isAddingCategory) {
            CategoryEditorSheet { name, color in
                Task { await viewModel.addCategory(named: name, color: color) }
            }
        }
        .alert("エラー", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var taskList: some View {
        if viewModel.visibleTasks.isEmpty {
            ContentUnavailableView("タスクはまだありません", systemImage: "checklist")
                .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.visibleTasks) { task in
                    TaskRow(
                        task: task,
                        dueDateText: viewModel.dueDateText(for: task),
                        remainingDaysText: viewModel.remainingDaysText(for: task),
                        isDueSoon: viewModel.isDueSoon(task),
                        categoryColor: viewModel.categoryColor(for: task)?.color,
                        onToggle: { Task { await viewModel.toggleCompletion(task) } }
                    )
                    .onTapGesture { viewModel.startEditing(task) }
                    .swipeActions {
                        Button("削除", systemImage: "trash", role: .destructive) {
                            Task { await viewModel.delete(task) }
                        }
                    }
                    .listRowSeparator(.hidden)
                    // 行の背景を透明にし、隣の行がカードの影を覆わないようにする
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(
                            top: 6, leading: Self.horizontalMargin, bottom: 6, trailing: Self.horizontalMargin)
                    )
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // 1件目のカードの影がリストの上端で切れないよう、リストをカテゴリの下端まで広げ、同じ分だけ中身を下げる
            .padding(.top, -Self.listTopShadowRoom)
            .contentMargins(.top, Self.listTopShadowRoom, for: .scrollContent)
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }
}
