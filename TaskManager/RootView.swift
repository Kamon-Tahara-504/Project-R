import HomeFeature
import SettingsFeature
import SwiftUI
import TaskListFeature
import UsageTimeFeature

/// タブで3画面を切り替え、利用時間外は休憩画面を全面に重ねる
struct RootView: View {
    private enum RootTab: Hashable {
        case home
        case todo
        case settings
    }

    /// タブバーを標準の位置から持ち上げる量（pt）
    private static let tabBarLift: CGFloat = 12
    /// タスクタブの位置（左から 0 始まり）。TabView に並べる順番と合わせる
    private static let todoTabIndex = 1

    @State private var selectedTab: RootTab = .home
    @State private var homeViewModel: HomeViewModel
    @State private var taskListViewModel: TaskListViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var usageTimeViewModel: UsageTimeViewModel
    @Environment(\.scenePhase) private var scenePhase
    private let daylightClock: DaylightClock

    init(dependencies: AppDependencies, daylightClock: DaylightClock) {
        self.daylightClock = daylightClock
        _homeViewModel = State(
            initialValue: HomeViewModel(
                taskService: dependencies.taskService,
                categoryRepository: dependencies.categoryRepository
            )
        )
        _taskListViewModel = State(
            initialValue: TaskListViewModel(
                taskService: dependencies.taskService,
                categoryRepository: dependencies.categoryRepository
            )
        )
        _settingsViewModel = State(
            initialValue: SettingsViewModel(
                settingsRepository: dependencies.settingsRepository,
                taskService: dependencies.taskService
            )
        )
        _usageTimeViewModel = State(
            initialValue: UsageTimeViewModel(settingsRepository: dependencies.settingsRepository)
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("ホーム", systemImage: "house", value: RootTab.home) {
                HomeView(viewModel: homeViewModel, daylightClock: daylightClock)
            }
            // タスク画面を開いている間は、同じタブを作成ボタンとして使う
            Tab(
                selectedTab == .todo ? "作成" : "タスク",
                systemImage: selectedTab == .todo ? "plus" : "checklist",
                value: RootTab.todo
            ) {
                TaskListView(viewModel: taskListViewModel)
            }
            Tab("設定", systemImage: "gearshape", value: RootTab.settings) {
                SettingsView(viewModel: settingsViewModel)
            }
        }
        .background {
            TabBarLift(amount: Self.tabBarLift)
            // タスクタブは選択中だけ「作成」ボタンになるため、選択中の見た目をボタンらしく塗る
            TabBarItemHighlight(index: Self.todoTabIndex, color: .systemBlue, isSelected: selectedTab == .todo)
            KeyboardDismissOnTap()
            // 設定画面の外観を、シートや休憩画面を含むアプリ全体に反映する
            WindowAppearance(mode: settingsViewModel.settings.appearance)
        }
        .overlay {
            if usageTimeViewModel.isLocked {
                RestView(availableHoursText: usageTimeViewModel.availableHoursText) {
                    usageTimeViewModel.unlock()
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: usageTimeViewModel.isLocked)
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                usageTimeViewModel.evaluate()
            case .background:
                usageTimeViewModel.didEnterBackground()
            default:
                break
            }
        }
    }

    /// 選択中のタブをもう一度押したことを検知するための選択状態。
    ///
    /// TabView は選択中のタブが押されたときも同じ値で set を呼ぶため、それをタスクの作成操作として扱う
    private var tabSelection: Binding<RootTab> {
        Binding(
            get: { selectedTab },
            set: { tab in
                if tab == .todo, selectedTab == .todo {
                    taskListViewModel.startCreatingTask()
                }
                selectedTab = tab
            }
        )
    }
}
