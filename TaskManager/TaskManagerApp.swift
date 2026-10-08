import HomeFeature
import Notifications
import SwiftUI
import UserNotifications

/// 依存関係を組み立てる場所（Composition Root）。組み立て以外のロジックは持たせない
@main
struct TaskManagerApp: App {
    /// 指定して起動すると、ホームの昼夜ゲージが `daylightDemoSecondsPerDay` 秒で 1 日分進む（見た目の確認用）
    static let daylightDemoArgument = "-DaylightDemo"
    /// デモで 24 時間分が経過するのにかける実時間（秒）
    static let daylightDemoSecondsPerDay: TimeInterval = 30

    private let dependencies: AppDependencies
    private let daylightClock: DaylightClock
    // UNUserNotificationCenter はデリゲートを弱参照で持つため、ここで保持し続ける
    private let notificationPresenter = ForegroundNotificationPresenter()

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains(AppDependencies.uiTestingArgument)
        daylightClock =
            arguments.contains(Self.daylightDemoArgument)
            ? .accelerated(secondsPerDay: Self.daylightDemoSecondsPerDay) : .realTime
        do {
            dependencies = try AppDependencies.make(isUITesting: isUITesting)
        } catch {
            // 保存領域を用意できない状態では、データを失わずに動作を続ける手段がないため起動を止める
            fatalError("依存関係の組み立てに失敗しました: \(error)")
        }
        UNUserNotificationCenter.current().delegate = notificationPresenter
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies, daylightClock: daylightClock)
        }
    }
}
