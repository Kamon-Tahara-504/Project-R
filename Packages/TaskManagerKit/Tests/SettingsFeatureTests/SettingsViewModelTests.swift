import Domain
import DomainTestSupport
import Foundation
import SettingsFeature
import Testing

@MainActor
struct SettingsViewModelTests {
    private func makeViewModel(fixture: TaskServiceFixture) -> SettingsViewModel {
        SettingsViewModel(settingsRepository: fixture.settingsRepository, taskService: fixture.service)
    }

    @Test("利用時間の変更はすぐに保存される")
    func usageTimeChangesArePersisted() {
        let fixture = TaskServiceFixture()
        let viewModel = makeViewModel(fixture: fixture)

        viewModel.setUsageTimeEnabled(true)
        viewModel.setUsageTimeStart(TimeOfDay(hour: 9, minute: 0))
        viewModel.setUsageTimeEnd(TimeOfDay(hour: 21, minute: 30))

        let saved = fixture.settingsRepository.load().usageTime
        #expect(saved.isEnabled)
        #expect(saved.start == TimeOfDay(hour: 9, minute: 0))
        #expect(saved.end == TimeOfDay(hour: 21, minute: 30))
    }

    @Test("見出しの利用時間は、ON なら時間帯、OFF なら制限なしを表示する")
    func usageTimeSummaryFollowsSettings() {
        let viewModel = makeViewModel(fixture: TaskServiceFixture())

        viewModel.setUsageTimeEnabled(false)
        #expect(viewModel.usageTimeSummaryText == "利用時間の制限なし")

        viewModel.setUsageTimeEnabled(true)
        viewModel.setUsageTimeStart(TimeOfDay(hour: 8, minute: 0))
        viewModel.setUsageTimeEnd(TimeOfDay(hour: 20, minute: 5))
        #expect(viewModel.usageTimeSummaryText == "利用時間 8:00〜20:05")
    }

    @Test("外観の変更はすぐに保存される")
    func appearanceChangeIsPersisted() {
        let fixture = TaskServiceFixture()
        let viewModel = makeViewModel(fixture: fixture)

        viewModel.setAppearance(.dark)

        #expect(viewModel.settings.appearance == .dark)
        #expect(fixture.settingsRepository.load().appearance == .dark)
    }

    @Test("通知を ON にしようとして拒否されたら、OFF のまま案内を出す")
    func deniedPermissionKeepsNotificationsOff() async {
        let fixture = TaskServiceFixture(
            settings: AppSettings(notificationsEnabled: false),
            isNotificationAuthorized: false
        )
        let viewModel = makeViewModel(fixture: fixture)

        await viewModel.setNotificationsEnabled(true)

        #expect(viewModel.isNotificationPermissionDenied)
        #expect(!viewModel.settings.notificationsEnabled)
        #expect(!fixture.settingsRepository.load().notificationsEnabled)
    }

    @Test("通知を OFF にすると登録済みの通知を取り消す")
    func disablingNotificationsCancelsAll() async {
        let task = TaskItem(title: "課題", notifyAt: Date().addingTimeInterval(3_600))
        let fixture = TaskServiceFixture(tasks: [task])
        await fixture.notificationScheduler.schedule(task)
        let viewModel = makeViewModel(fixture: fixture)

        await viewModel.setNotificationsEnabled(false)

        #expect(!fixture.settingsRepository.load().notificationsEnabled)
        #expect(await fixture.notificationScheduler.scheduledIDs.isEmpty)
    }

    @Test("タスクデータを削除すると全タスクが消え、完了を知らせる")
    func deleteAllTasks() async throws {
        let fixture = TaskServiceFixture(tasks: [TaskItem(title: "A"), TaskItem(title: "B")])
        let viewModel = makeViewModel(fixture: fixture)

        await viewModel.deleteAllTasks()

        #expect(try await fixture.taskRepository.fetchAll().isEmpty)
        #expect(viewModel.didDeleteAllTasks)
    }
}
