import Domain
import DomainTestSupport
import Foundation
import TaskListFeature
import Testing

@MainActor
struct TaskListViewModelTests {
    private struct DummyError: Error {}

    private let now = TestCalendar.date(2026, 1, 1, 9, 0)
    private let school = TaskCategory(name: "学校課題", sortOrder: 0)
    private let hobby = TaskCategory(name: "自主制作", sortOrder: 1)

    private func makeViewModel(fixture: TaskServiceFixture) -> TaskListViewModel {
        let now = now
        return TaskListViewModel(
            taskService: fixture.service,
            categoryRepository: fixture.categoryRepository,
            now: { now },
            calendar: TestCalendar.calendar
        )
    }

    @Test("カテゴリを選ぶとそのカテゴリのタスクだけを表示し、「全て」では全件を表示する")
    func filterByCategory() async {
        let schoolTask = TaskItem(title: "レポート", categoryID: school.id)
        let hobbyTask = TaskItem(title: "作品", categoryID: hobby.id)
        let fixture = TaskServiceFixture(tasks: [schoolTask, hobbyTask], categories: [school, hobby])
        let viewModel = makeViewModel(fixture: fixture)
        await viewModel.load()

        viewModel.selectedCategoryID = school.id
        #expect(viewModel.visibleTasks == [schoolTask])

        viewModel.selectedCategoryID = nil
        #expect(viewModel.visibleTasks.count == 2)
    }

    @Test("件数は選択中のカテゴリで表示しているタスクを、完了済みも含めて数える")
    func countTextFollowsSelectedCategory() async {
        let fixture = TaskServiceFixture(
            tasks: [
                TaskItem(title: "レポート", categoryID: school.id),
                TaskItem(title: "小テスト", isCompleted: true, categoryID: school.id),
                TaskItem(title: "作品", categoryID: hobby.id),
            ],
            categories: [school, hobby]
        )
        let viewModel = makeViewModel(fixture: fixture)
        await viewModel.load()
        #expect(viewModel.visibleTaskCountText == "3件のタスク")

        viewModel.selectedCategoryID = school.id
        #expect(viewModel.visibleTaskCountText == "2件のタスク")
    }

    @Test("締切順では締切の近い順に並び、締切のないタスクは末尾になる")
    func sortByDueDate() async {
        let noDue = TaskItem(title: "締切なし", createdAt: TestCalendar.date(2026, 1, 1, 8, 0))
        let later = TaskItem(title: "後", dueDate: TestCalendar.date(2026, 1, 20))
        let sooner = TaskItem(title: "先", dueDate: TestCalendar.date(2026, 1, 5))
        let viewModel = makeViewModel(fixture: TaskServiceFixture(tasks: [noDue, later, sooner]))
        await viewModel.load()

        viewModel.sortOrder = .dueDate

        #expect(viewModel.visibleTasks.map(\.title) == ["先", "後", "締切なし"])
    }

    @Test("選択中のカテゴリを削除すると「全て」に戻る")
    func deletingSelectedCategoryResetsSelection() async {
        let viewModel = makeViewModel(fixture: TaskServiceFixture(categories: [school, hobby]))
        await viewModel.load()
        viewModel.selectedCategoryID = school.id

        await viewModel.deleteCategory(school)

        #expect(viewModel.selectedCategoryID == nil)
        #expect(viewModel.categories == [hobby])
    }

    @Test("作成を始めると、新規作成のシートを開く")
    func startCreatingTaskOpensNewEditor() async throws {
        let viewModel = makeViewModel(fixture: TaskServiceFixture())

        viewModel.startCreatingTask()

        let editor = try #require(viewModel.editor)
        #expect(editor.isNew)
    }

    @Test("タスクを選ぶと、そのタスクの編集シートを開く")
    func startEditingOpensExistingEditor() async throws {
        let task = TaskItem(title: "レポート")
        let viewModel = makeViewModel(fixture: TaskServiceFixture(tasks: [task]))

        viewModel.startEditing(task)

        let editor = try #require(viewModel.editor)
        #expect(!editor.isNew)
    }

    @Test("カテゴリは末尾に追加され、追加したカテゴリが選択される")
    func addCategoryAppendsAndSelects() async {
        let viewModel = makeViewModel(fixture: TaskServiceFixture(categories: [school, hobby]))
        await viewModel.load()

        await viewModel.addCategory(named: "コンテスト", color: .orange)

        #expect(viewModel.categories.map(\.name) == ["学校課題", "自主制作", "コンテスト"])
        #expect(viewModel.selectedCategoryID == viewModel.categories.last?.id)
    }

    @Test("カテゴリは選んだ色で保存される")
    func addCategorySavesColor() async throws {
        let fixture = TaskServiceFixture()
        let viewModel = makeViewModel(fixture: fixture)

        await viewModel.addCategory(named: "アルバイト", color: .green)

        #expect(try await fixture.categoryRepository.fetchAll().first?.color == .green)
    }

    @Test("タスクの色は属するカテゴリの色になり、未分類のタスクは色を持たない")
    func categoryColorFollowsCategory() async {
        let pinkCategory = TaskCategory(name: "趣味", sortOrder: 0, color: .pink)
        let categorized = TaskItem(title: "作品", categoryID: pinkCategory.id)
        let uncategorized = TaskItem(title: "買い物")
        let viewModel = makeViewModel(
            fixture: TaskServiceFixture(tasks: [categorized, uncategorized], categories: [pinkCategory])
        )
        await viewModel.load()

        #expect(viewModel.categoryColor(for: categorized) == .pink)
        #expect(viewModel.categoryColor(for: uncategorized) == nil)
    }

    @Test(
        "残り日数の表示",
        arguments: [
            (TestCalendar.date(2026, 1, 8), "残り7日"),
            (TestCalendar.date(2026, 1, 1, 23, 0), "今日まで"),
            (TestCalendar.date(2025, 12, 31), "期限切れ"),
            (TestCalendar.date(2026, 2, 1), "残り1ヶ月以上"),
            (TestCalendar.date(2026, 1, 31), "残り30日"),
        ]
    )
    func remainingDaysText(dueDate: Date, expected: String) {
        let viewModel = makeViewModel(fixture: TaskServiceFixture())
        #expect(viewModel.remainingDaysText(for: TaskItem(title: "課題", dueDate: dueDate)) == expected)
    }

    @Test("締切日は「1月1日(木)」の形式で表示する")
    func dueDateText() {
        let viewModel = makeViewModel(fixture: TaskServiceFixture())
        let task = TaskItem(title: "課題", dueDate: TestCalendar.date(2026, 1, 1))
        #expect(viewModel.dueDateText(for: task) == "1月1日(木)")
    }

    @Test("読み込みに失敗するとエラー文言を保持する")
    func loadFailureSetsErrorMessage() async {
        let settings = InMemorySettingsRepository()
        let service = TaskService(
            taskRepository: MockTaskRepository(fetchError: DummyError()),
            notificationScheduler: MockNotificationScheduler(),
            settingsRepository: settings
        )
        let viewModel = TaskListViewModel(taskService: service, categoryRepository: MockCategoryRepository())

        await viewModel.load()

        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }
}
