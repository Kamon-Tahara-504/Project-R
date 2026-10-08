import Foundation

/// タスクの通知の登録・取り消しを抽象化する窓口。
///
/// 通知の失敗でタスクの保存まで失敗させないよう、登録系の操作はエラーを投げない。
public protocol TaskNotificationScheduler: Sendable {
    /// 通知の許可を求める。すでに決まっていればその結果を返す
    func requestAuthorization() async -> Bool
    /// `task.notifyAt` に通知を登録する。同じタスクの既存の通知は置き換える
    func schedule(_ task: TaskItem) async
    func cancel(id: TaskItem.ID) async
    func cancelAll() async
}
