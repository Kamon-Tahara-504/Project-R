import SwiftData

/// 保存対象のモデル一覧を1か所に閉じ込め、App やテストがモデルの型を知らずにコンテナを作れるようにする。
public enum ModelContainerFactory {
    /// - Parameter isStoredInMemoryOnly: テストや Preview では `true` にして、端末のデータを汚さないようにする
    public static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([TaskItemRecord.self, TaskCategoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
