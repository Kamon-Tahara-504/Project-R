import Domain
import Foundation
import Persistence
import Testing

struct UserDefaultsSettingsRepositoryTests {
    private let defaults: UserDefaults
    private let repository: UserDefaultsSettingsRepository

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "UserDefaultsSettingsRepositoryTests-\(UUID())"))
        repository = UserDefaultsSettingsRepository(defaults: defaults)
    }

    @Test("外観の項目を足す前に保存した設定も、利用時間などを失わずに読める")
    func loadSettingsSavedBeforeAppearanceExisted() throws {
        let json = """
            {"usageTime":{"isEnabled":true,"start":{"hour":9,"minute":30},"end":{"hour":21,"minute":0}},
             "notificationsEnabled":false}
            """
        defaults.set(try #require(json.data(using: .utf8)), forKey: "appSettings")

        let settings = repository.load()

        #expect(settings.usageTime.isEnabled)
        #expect(settings.usageTime.start == TimeOfDay(hour: 9, minute: 30))
        #expect(!settings.notificationsEnabled)
        #expect(settings.appearance == .system)
    }

    @Test("未保存なら初期値を返す")
    func loadReturnsDefaultWhenEmpty() {
        #expect(repository.load() == .default)
    }

    @Test("保存した設定を読み出せる")
    func saveAndLoad() {
        let settings = AppSettings(
            usageTime: UsageTimeSettings(
                isEnabled: true,
                start: TimeOfDay(hour: 9, minute: 30),
                end: TimeOfDay(hour: 21, minute: 0)
            ),
            notificationsEnabled: false,
            appearance: .dark
        )

        repository.save(settings)

        #expect(repository.load() == settings)
    }
}
