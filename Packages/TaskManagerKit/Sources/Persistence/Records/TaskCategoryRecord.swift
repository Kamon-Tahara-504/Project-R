import Domain
import Foundation
import SwiftData

/// `TaskCategory` を SwiftData に保存するための型。
///
/// タスクとはリレーションを張らず、タスク側の `categoryID` で紐付ける。
/// Domain の値型との変換を単純に保つため。
@Model
final class TaskCategoryRecord {
    /// 色が保存されていない（色を選べるようになる前に作られた）カテゴリに使う色
    static let fallbackColor = CategoryColor.blue

    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    /// `CategoryColor.rawValue`。既存のデータを移行なしで読めるよう、省略できる項目にしている
    var colorRawValue: String?

    init(_ category: TaskCategory) {
        id = category.id
        name = category.name
        sortOrder = category.sortOrder
        colorRawValue = category.color.rawValue
    }

    func toDomain() -> TaskCategory {
        TaskCategory(
            id: id,
            name: name,
            sortOrder: sortOrder,
            color: colorRawValue.flatMap(CategoryColor.init(rawValue:)) ?? Self.fallbackColor
        )
    }
}
