import Domain
import DomainTestSupport
import Foundation
import HomeFeature
import Testing

@MainActor
struct HomeViewModelTests {
    private let now = TestCalendar.date(2026, 1, 1, 9, 0)

    private func makeViewModel(tasks: [TaskItem]) -> HomeViewModel {
        let now = now
        return HomeViewModel(
            taskService: TaskServiceFixture(tasks: tasks).service,
            categoryRepository: MockCategoryRepository(),
            now: { now },
            calendar: TestCalendar.calendar
        )
    }

    private func task(_ title: String, start: Date, minutes: Double = 60) -> TaskItem {
        TaskItem(title: title, schedule: TaskSchedule(start: start, end: start.addingTimeInterval(minutes * 60)))
    }

    @Test("今日実施するタスクだけを開始時刻順に表示する")
    func todayTasksSortedByStart() async {
        let evening = task("夜", start: TestCalendar.date(2026, 1, 1, 20, 0))
        let morning = task("朝", start: TestCalendar.date(2026, 1, 1, 6, 0))
        let afternoon = task("昼", start: TestCalendar.date(2026, 1, 1, 13, 0))
        let tomorrow = task("明日", start: TestCalendar.date(2026, 1, 2, 7, 0))
        let unscheduled = TaskItem(title: "予定なし")
        let viewModel = makeViewModel(tasks: [evening, morning, afternoon, tomorrow, unscheduled])

        await viewModel.load()

        #expect(viewModel.todayTasks.map(\.title) == ["朝", "昼", "夜"])
    }

    @Test("実施時間は「11:30AM-12:30PM」の形式で表示する")
    func timeRangeText() {
        let viewModel = makeViewModel(tasks: [])
        let item = task("作業", start: TestCalendar.date(2026, 1, 1, 11, 30))
        #expect(viewModel.timeRangeText(for: item) == "11:30AM-12:30PM")
    }
}
