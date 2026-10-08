import Foundation

/// 設定画面で変更できるアプリ全体の設定
public struct AppSettings: Equatable, Codable, Sendable {
    public var usageTime: UsageTimeSettings
    /// アプリ全体の通知の ON/OFF。OFF の間はタスクごとの通知日時が設定されていても通知しない
    public var notificationsEnabled: Bool
    public var appearance: AppearanceMode

    public init(
        usageTime: UsageTimeSettings = .default,
        notificationsEnabled: Bool = true,
        appearance: AppearanceMode = .system
    ) {
        self.usageTime = usageTime
        self.notificationsEnabled = notificationsEnabled
        self.appearance = appearance
    }

    public static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case usageTime
        case notificationsEnabled
        case appearance
    }

    /// 後から足した項目は、それより前に保存された設定に含まれない。
    /// 1 項目が欠けただけで全体を読めずに初期値へ戻ると、利用時間などの設定まで失われるため、欠けた項目だけ初期値で補う
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        usageTime = try container.decode(UsageTimeSettings.self, forKey: .usageTime)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        appearance = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system
    }
}
