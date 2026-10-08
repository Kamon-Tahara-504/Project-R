import Foundation

/// タスクの分類（学校課題、自主制作など）。ユーザーが追加・削除できる
public struct TaskCategory: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    /// タブの表示順。小さいほど左に並ぶ
    public var sortOrder: Int
    /// タブやタスクカードの色分けに使う色
    public var color: CategoryColor

    public init(id: UUID = UUID(), name: String, sortOrder: Int, color: CategoryColor = .blue) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.color = color
    }
}
