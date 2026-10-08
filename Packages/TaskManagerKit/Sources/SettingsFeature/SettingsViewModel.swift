import Domain
import Foundation
import Observation

/// 設定画面の状態とロジック
@MainActor
@Observable
public final class SettingsViewModel {
    public private(set) var settings: AppSettings
    /// 通知を ON にしようとしたが、iOS 側で許可されていなかった
    public private(set) var isNotificationPermissionDenied = false
    public private(set) var didDeleteAllTasks = false
    public private(set) var errorMessage: String?

    private let settingsRepository: any SettingsRepository
    private let taskService: TaskService

    public init(settingsRepository: any SettingsRepository, taskService: TaskService) {
        self.settingsRepository = settingsRepository
        self.taskService = taskService
        settings = settingsRepository.load()
    }

    /// 見出しに添える、今の利用時間の設定。例: 「利用時間 8:00〜20:00」「利用時間の制限なし」
    public var usageTimeSummaryText: String {
        let usageTime = settings.usageTime
        return usageTime.isEnabled ? "利用時間 \(usageTime.start)〜\(usageTime.end)" : "利用時間の制限なし"
    }

    public func setUsageTimeEnabled(_ isEnabled: Bool) {
        update { $0.usageTime.isEnabled = isEnabled }
    }

    public func setUsageTimeStart(_ time: TimeOfDay) {
        update { $0.usageTime.start = time }
    }

    public func setUsageTimeEnd(_ time: TimeOfDay) {
        update { $0.usageTime.end = time }
    }

    public func setAppearance(_ appearance: AppearanceMode) {
        update { $0.appearance = appearance }
    }

    /// ON にするときは通知の許可を求め、許可されなければ OFF のままにする
    public func setNotificationsEnabled(_ isEnabled: Bool) async {
        if isEnabled, !(await taskService.requestNotificationAuthorization()) {
            isNotificationPermissionDenied = true
            return
        }
        update { $0.notificationsEnabled = isEnabled }
        do {
            try await taskService.rescheduleAllNotifications()
        } catch {
            errorMessage = "通知の設定を反映できませんでした"
        }
    }

    public func deleteAllTasks() async {
        do {
            try await taskService.deleteAll()
            didDeleteAllTasks = true
        } catch {
            errorMessage = "タスクデータを削除できませんでした"
        }
    }

    public func dismissPermissionAlert() {
        isNotificationPermissionDenied = false
    }

    public func dismissDeleteResult() {
        didDeleteAllTasks = false
    }

    public func dismissError() {
        errorMessage = nil
    }

    private func update(_ change: (inout AppSettings) -> Void) {
        change(&settings)
        settingsRepository.save(settings)
    }
}
