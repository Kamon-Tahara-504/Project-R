/// カテゴリに付ける色の種類。
///
/// Domain を画面の部品（SwiftUI）から切り離すため、ここでは種類だけを表し、実際の色の値は画面側で決める。
/// 保存には `rawValue` を使うため、名前を変えると保存済みの色が読めなくなる点に注意する
public enum CategoryColor: String, CaseIterable, Sendable {
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case purple
    case pink
}
