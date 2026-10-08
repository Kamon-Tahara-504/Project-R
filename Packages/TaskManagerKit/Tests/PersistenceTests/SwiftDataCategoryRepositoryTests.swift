import Domain
import Foundation
import SwiftData
import Testing

@testable import Persistence

@MainActor
struct SwiftDataCategoryRepositoryTests {
    private let container: ModelContainer
    private let taskRepository: SwiftDataTaskRepository
    private let categoryRepository: SwiftDataCategoryRepository
    private let defaults: UserDefaults

    init() throws {
        container = try ModelContainerFactory.make(isStoredInMemoryOnly: true)
        taskRepository = SwiftDataTaskRepository(container: container)
        categoryRepository = SwiftDataCategoryRepository(container: container)
        defaults = try #require(UserDefaults(suiteName: "SwiftDataCategoryRepositoryTests-\(UUID())"))
    }

    @Test("表示順の昇順で取得できる")
    func fetchAllSortedBySortOrder() async throws {
        let second = TaskCategory(name: "B", sortOrder: 1)
        let first = TaskCategory(name: "A", sortOrder: 0)
        try await categoryRepository.add(second)
        try await categoryRepository.add(first)

        #expect(try await categoryRepository.fetchAll() == [first, second])
    }

    @Test("カテゴリの色が保存され、そのまま読み出せる")
    func colorRoundTrip() async throws {
        let category = TaskCategory(name: "アルバイト", sortOrder: 0, color: .pink)
        try await categoryRepository.add(category)

        #expect(try await categoryRepository.fetchAll().first?.color == .pink)
    }

    @Test("色が保存されていないカテゴリは青として読み出す")
    func missingColorFallsBackToBlue() async throws {
        let record = TaskCategoryRecord(TaskCategory(name: "以前のカテゴリ", sortOrder: 0, color: .red))
        record.colorRawValue = nil
        container.mainContext.insert(record)
        try container.mainContext.save()

        #expect(try await categoryRepository.fetchAll().first?.color == .blue)
    }

    @Test("カテゴリを削除すると、属していたタスクは未分類に戻る")
    func deleteResetsTaskCategory() async throws {
        let category = TaskCategory(name: "学校課題", sortOrder: 0)
        try await categoryRepository.add(category)
        let task = TaskItem(title: "レポート", categoryID: category.id)
        try await taskRepository.add(task)

        try await categoryRepository.delete(id: category.id)

        #expect(try await categoryRepository.fetchAll().isEmpty)
        #expect(try await taskRepository.fetchAll().first?.categoryID == nil)
    }

    @Test("新規インストールではカテゴリを投入しない")
    func freshInstallHasNoCategories() async throws {
        try categoryRepository.removeLegacyDefaultsIfNeeded(defaults: defaults)

        #expect(try await categoryRepository.fetchAll().isEmpty)
    }

    @Test("以前の版が投入した初期カテゴリを削除し、ユーザーが作ったカテゴリは残す")
    func removeLegacyDefaults() async throws {
        defaults.set(true, forKey: "didSeedDefaultCategories")
        let school = TaskCategory(name: "学校課題", sortOrder: 0)
        let custom = TaskCategory(name: "アルバイト", sortOrder: 3)
        for category in [
            school, TaskCategory(name: "自主制作", sortOrder: 1), TaskCategory(name: "コンテスト", sortOrder: 2), custom,
        ] {
            try await categoryRepository.add(category)
        }
        let task = TaskItem(title: "レポート", categoryID: school.id)
        try await taskRepository.add(task)

        try categoryRepository.removeLegacyDefaultsIfNeeded(defaults: defaults)

        #expect(try await categoryRepository.fetchAll() == [custom])
        #expect(try await taskRepository.fetchAll().first?.categoryID == nil)
    }

    @Test("初期カテゴリの削除は1回だけで、その後に同じ名前で作ったカテゴリは消さない")
    func removeLegacyDefaultsOnlyOnce() async throws {
        defaults.set(true, forKey: "didSeedDefaultCategories")
        try categoryRepository.removeLegacyDefaultsIfNeeded(defaults: defaults)

        let recreated = TaskCategory(name: "学校課題", sortOrder: 0)
        try await categoryRepository.add(recreated)
        try categoryRepository.removeLegacyDefaultsIfNeeded(defaults: defaults)

        #expect(try await categoryRepository.fetchAll() == [recreated])
    }
}
