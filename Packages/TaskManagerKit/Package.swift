// swift-tools-version: 6.0

import PackageDescription

// 依存の向きは Feature -> Domain <- Persistence / Notifications に限定する。
// Feature から Persistence や Notifications を参照できないことを、ターゲットの依存定義でコンパイラに強制させる。
// 複数の Feature で使う画面（TaskEditorFeature）だけは Feature 同士の依存を許す。
// DesignSystem は画面の見た目の共通部品だけを持ち、Domain を含む他のターゲットに依存させない。
let package = Package(
    name: "TaskManagerKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Notifications", targets: ["Notifications"]),
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
        .library(name: "TaskListFeature", targets: ["TaskListFeature"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
        .library(name: "UsageTimeFeature", targets: ["UsageTimeFeature"]),
    ],
    targets: [
        .target(name: "Domain"),
        // テスト専用のモック。products に含めないことでアプリから参照できないようにしている
        .target(name: "DomainTestSupport", dependencies: ["Domain"]),
        .target(name: "Persistence", dependencies: ["Domain"]),
        .target(name: "Notifications", dependencies: ["Domain"]),
        .target(name: "DesignSystem"),
        .target(name: "TaskEditorFeature", dependencies: ["Domain", "DesignSystem"]),
        .target(name: "TaskListFeature", dependencies: ["Domain", "DesignSystem", "TaskEditorFeature"]),
        .target(
            name: "HomeFeature",
            dependencies: ["Domain", "TaskEditorFeature"],
            resources: [.process("Resources")]
        ),
        .target(name: "SettingsFeature", dependencies: ["Domain", "DesignSystem"]),
        .target(name: "UsageTimeFeature", dependencies: ["Domain"]),

        .testTarget(name: "DomainTests", dependencies: ["Domain", "DomainTestSupport"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Domain"]),
        .testTarget(
            name: "TaskEditorFeatureTests",
            dependencies: ["TaskEditorFeature", "Domain", "DomainTestSupport"]
        ),
        .testTarget(
            name: "TaskListFeatureTests",
            dependencies: ["TaskListFeature", "Domain", "DomainTestSupport"]
        ),
        .testTarget(name: "HomeFeatureTests", dependencies: ["HomeFeature", "Domain", "DomainTestSupport"]),
        .testTarget(
            name: "SettingsFeatureTests",
            dependencies: ["SettingsFeature", "Domain", "DomainTestSupport"]
        ),
        .testTarget(
            name: "UsageTimeFeatureTests",
            dependencies: ["UsageTimeFeature", "Domain", "DomainTestSupport"]
        ),
    ]
)
