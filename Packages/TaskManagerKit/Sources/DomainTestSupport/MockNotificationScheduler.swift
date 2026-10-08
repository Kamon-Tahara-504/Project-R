import Domain

/// 呼び出しを記録するだけの `TaskNotificationScheduler`
public actor MockNotificationScheduler: TaskNotificationScheduler {
    /// 現在登録されている通知のタスク ID
    public private(set) var scheduledIDs: Set<TaskItem.ID> = []
    public private(set) var cancelAllCount = 0
    private let isAuthorized: Bool

    public init(isAuthorized: Bool = true) {
        self.isAuthorized = isAuthorized
    }

    public func requestAuthorization() async -> Bool {
        isAuthorized
    }

    public func schedule(_ task: TaskItem) async {
        scheduledIDs.insert(task.id)
    }

    public func cancel(id: TaskItem.ID) async {
        scheduledIDs.remove(id)
    }

    public func cancelAll() async {
        scheduledIDs.removeAll()
        cancelAllCount += 1
    }
}
