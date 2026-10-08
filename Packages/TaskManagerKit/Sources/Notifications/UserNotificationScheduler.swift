import Domain
import Foundation
import UserNotifications

/// `UNUserNotificationCenter` による `TaskNotificationScheduler` の実装。
///
/// 通知の識別子にタスクの ID を使い、同じタスクの通知を上書き・取り消しできるようにしている。
public final class UserNotificationScheduler: TaskNotificationScheduler {
    public init() {}

    public func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    public func schedule(_ task: TaskItem) async {
        guard let notifyAt = task.notifyAt, await requestAuthorization() else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = "設定した通知の時刻になりました"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifyAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)

        // 通知の登録に失敗してもタスクの保存は成立させたいため、エラーは握りつぶす
        try? await UNUserNotificationCenter.current().add(request)
    }

    public func cancel(id: TaskItem.ID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [id.uuidString])
    }

    public func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
