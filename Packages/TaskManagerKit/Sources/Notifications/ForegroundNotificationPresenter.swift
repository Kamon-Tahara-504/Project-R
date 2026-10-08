import UserNotifications

/// アプリを開いている最中に届いた通知もバナーで表示させるためのデリゲート。
///
/// iOS は既定ではフォアグラウンド中の通知を表示しないため、
/// アプリを使いながら通知時刻を迎えると気付けなくなるのを防ぐ。
public final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    override public init() {
        super.init()
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
