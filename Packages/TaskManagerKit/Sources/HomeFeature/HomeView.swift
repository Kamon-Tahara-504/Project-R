import Domain
import SwiftUI
import TaskEditorFeature

/// ホーム画面。今日実施するタスクを、背景イラストの上に表示する
public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var editor: TaskEditorViewModel?
    /// 日付と時刻の行の中心の、画面の上端からの高さ。背景の天井の梁をこの高さに揃える
    @State private var dateRowMidY: CGFloat?
    private let daylightClock: DaylightClock

    public init(viewModel: HomeViewModel, daylightClock: DaylightClock = .realTime) {
        _viewModel = State(initialValue: viewModel)
        self.daylightClock = daylightClock
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DateHeader(daylightClock: daylightClock) { dateRowMidY = $0 }

            Spacer(minLength: 0)

            TodayTaskCard(entries: entries) { task in
                editor = viewModel.makeEditor(for: task)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        // 日付の帯を画面上部へ寄せるため、上だけ余白を詰める
        .padding(.top, 10)
        .background { RoomBackground(daylightClock: daylightClock, beamTargetY: dateRowMidY) }
        .task { await viewModel.load() }
        .sheet(item: $editor) { editor in
            TaskEditorView(viewModel: editor) {
                Task { await viewModel.load() }
            }
        }
        .alert("エラー", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var entries: [TodayTaskCard.Entry] {
        viewModel.todayTasks.map { task in
            TodayTaskCard.Entry(task: task, timeRangeText: viewModel.timeRangeText(for: task) ?? "")
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }
}
