import Domain
import DomainTestSupport
import Foundation
import TaskEditorFeature
import Testing

@MainActor
struct TaskEditorViewModelTests {
    private let now = TestCalendar.date(2026, 1, 1, 9, 0)
    private let calendar = TestCalendar.calendar

    private func makeViewModel(task: TaskItem? = nil, fixture: TaskServiceFixture) -> TaskEditorViewModel {
        let now = now
        return TaskEditorViewModel(
            task: task,
            categories: [],
            taskService: fixture.service,
            now: { now },
            calendar: calendar
        )
    }

    @Test("新規作成では、終了時刻を開始日の時刻として保存する")
    func saveNewTaskCombinesScheduleEndWithStartDay() async throws {
        let fixture = TaskServiceFixture()
        let viewModel = makeViewModel(fixture: fixture)
        viewModel.title = "  作業  "
        viewModel.hasSchedule = true
        viewModel.scheduleStart = TestCalendar.date(2026, 1, 5, 10, 0)
        viewModel.scheduleEnd = TestCalendar.date(2026, 1, 1, 11, 30)

        #expect(await viewModel.save())

        let saved = try #require(try await fixture.taskRepository.fetchAll().first)
        #expect(saved.title == "作業")
        #expect(saved.schedule?.end == TestCalendar.date(2026, 1, 5, 11, 30))
        #expect(saved.dueDate == nil)
    }

    @Test("スキームのない URL は保存できない")
    func invalidURLIsRejected() async throws {
        let fixture = TaskServiceFixture()
        let viewModel = makeViewModel(fixture: fixture)
        viewModel.title = "課題"
        viewModel.urlText = "example.com"

        #expect(await viewModel.save() == false)
        #expect(viewModel.errorMessage != nil)
        #expect(try await fixture.taskRepository.fetchAll().isEmpty)
    }

    @Test("タイトルが空白だけなら保存できない")
    func blankTitleCannotBeSaved() {
        let viewModel = makeViewModel(fixture: TaskServiceFixture())
        viewModel.title = "   "
        #expect(!viewModel.canSave)
    }

    @Test("編集では ID・作成日時・完了日時を引き継ぐ")
    func editKeepsIdentity() async throws {
        let original = TaskItem(
            title: "前", completedAt: TestCalendar.date(2025, 12, 2), createdAt: TestCalendar.date(2025, 12, 1))
        let fixture = TaskServiceFixture(tasks: [original])
        let viewModel = makeViewModel(task: original, fixture: fixture)
        viewModel.title = "後"

        #expect(await viewModel.save())

        let saved = try #require(try await fixture.taskRepository.fetchAll().first)
        #expect(saved.id == original.id)
        #expect(saved.createdAt == original.createdAt)
        #expect(saved.completedAt == original.completedAt)
        #expect(saved.title == "後")
    }

    @Test("削除できる")
    func delete() async throws {
        let original = TaskItem(title: "削除対象")
        let fixture = TaskServiceFixture(tasks: [original])

        #expect(await makeViewModel(task: original, fixture: fixture).delete())
        #expect(try await fixture.taskRepository.fetchAll().isEmpty)
    }
}
