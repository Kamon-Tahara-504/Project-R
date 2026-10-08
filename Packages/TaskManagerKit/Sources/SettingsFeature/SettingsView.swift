import DesignSystem
import Domain
import SwiftUI
import UIKit

/// 設定画面。利用時間・通知・タスクデータの削除を、iOS の設定アプリと同じ並びのリキッドグラスのカードで行う
public struct SettingsView: View {
    /// 利用時間が OFF の間の、時刻の行の不透明度
    private static let disabledOpacity = 0.4
    /// カード同士の間隔
    private static let cardSpacing: CGFloat = 20
    /// 画面の左右の余白。タスク画面と揃える
    private static let horizontalMargin: CGFloat = 16
    /// スクロール領域の上端に確保する、カードの影の分の余白。タスク画面のリストと同じ方法で影が切れないようにする
    private static let topShadowRoom: CGFloat = 12

    @State private var viewModel: SettingsViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.openURL) private var openURL

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        // タブを切り替えても見出しの位置が変わらないよう、ナビゲーションバーではなくタスク画面と同じ見出しを使う
        VStack(spacing: 12) {
            ScreenHeader(title: "設定", subtitle: viewModel.usageTimeSummaryText, titleIdentifier: "settingsTitle")
                .padding(.horizontal, Self.horizontalMargin)
            ScrollView {
                VStack(spacing: Self.cardSpacing) {
                    usageTimeCard
                    notificationCard
                    appearanceCard
                    dataCard
                }
                .padding(.horizontal, Self.horizontalMargin)
                .padding(.bottom, Self.horizontalMargin)
            }
            .padding(.top, -Self.topShadowRoom)
            .contentMargins(.top, Self.topShadowRoom, for: .scrollContent)
        }
        .background { ScreenBackground() }
        .animation(.default, value: viewModel.settings.usageTime.isEnabled)
        .alert("通知が許可されていません", isPresented: isShowingPermissionAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定アプリでこのアプリの通知を許可してください。")
        }
        .alert("タスクデータを削除しました", isPresented: isShowingDeleteResult) {
            Button("OK", role: .cancel) {}
        }
        .alert("エラー", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var usageTimeCard: some View {
        SettingsCard {
            SettingsRow {
                Toggle(isOn: usageTimeEnabled) {
                    SettingsLabel(title: "利用時間", systemName: "hourglass", color: .indigo)
                }
            }
            SettingsRowDivider()
            // OFF の間も設定済みの時刻が分かるよう、隠さずに半透明で操作できなくする
            Group {
                SettingsRow {
                    DatePicker(selection: startTime, displayedComponents: .hourAndMinute) {
                        SettingsLabel(title: "開始", systemName: "sun.max.fill", color: .orange)
                    }
                }
                SettingsRowDivider()
                SettingsRow {
                    DatePicker(selection: endTime, displayedComponents: .hourAndMinute) {
                        SettingsLabel(title: "終了", systemName: "moon.fill", color: .blue)
                    }
                }
            }
            .disabled(!viewModel.settings.usageTime.isEnabled)
            .opacity(viewModel.settings.usageTime.isEnabled ? 1 : Self.disabledOpacity)
            SettingsDescription(
                text: "開始から終了までの間だけアプリを使えるようにします。時間外にアプリを開くと休憩画面が表示され、確認したときだけタスクを見られます。"
            )
        }
    }

    private var notificationCard: some View {
        SettingsCard {
            SettingsRow {
                Toggle(isOn: notificationsEnabled) {
                    SettingsLabel(title: "通知", systemName: "bell.badge.fill", color: .red)
                }
            }
            SettingsDescription(text: "タスクに設定した通知日時にお知らせします。")
        }
    }

    private var appearanceCard: some View {
        SettingsCard {
            SettingsRow {
                HStack {
                    SettingsLabel(title: "外観", systemName: "circle.lefthalf.filled", color: .purple)
                    Spacer()
                    // 選択肢が 3 つと少なく、どれが選ばれているかを一目で分かるようにするため、メニューではなく並べて見せる
                    Picker("外観", selection: appearance) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                    .accessibilityIdentifier("appearancePicker")
                }
            }
            SettingsDescription(text: "「自動」は端末のライト / ダークの設定に合わせて切り替わります。")
        }
    }

    private var dataCard: some View {
        SettingsCard {
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                SettingsRow {
                    SettingsLabel(title: "タスクデータを削除", systemName: "trash.fill", color: .gray)
                        .foregroundStyle(.red)
                }
                // 文字のない余白を押しても反応するよう、行全体を押せる範囲にする
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "すべてのタスクを削除しますか？",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    Task { await viewModel.deleteAllTasks() }
                }
            } message: {
                Text("この操作は取り消せません。カテゴリと設定は残ります。")
            }
            SettingsDescription(text: "カテゴリと設定は削除されません。")
        }
    }

    private var appearance: Binding<AppearanceMode> {
        Binding(
            get: { viewModel.settings.appearance },
            set: { viewModel.setAppearance($0) }
        )
    }

    private var usageTimeEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.settings.usageTime.isEnabled },
            set: { viewModel.setUsageTimeEnabled($0) }
        )
    }

    /// 時刻は日付を持たないため、DatePicker で扱えるよう今日の日付を付けて渡す
    private var startTime: Binding<Date> {
        Binding(
            get: { viewModel.settings.usageTime.start.date(on: .now) },
            set: { viewModel.setUsageTimeStart(TimeOfDay(date: $0)) }
        )
    }

    private var endTime: Binding<Date> {
        Binding(
            get: { viewModel.settings.usageTime.end.date(on: .now) },
            set: { viewModel.setUsageTimeEnd(TimeOfDay(date: $0)) }
        )
    }

    private var notificationsEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.settings.notificationsEnabled },
            set: { isEnabled in Task { await viewModel.setNotificationsEnabled(isEnabled) } }
        )
    }

    private var isShowingPermissionAlert: Binding<Bool> {
        Binding(
            get: { viewModel.isNotificationPermissionDenied },
            set: { if !$0 { viewModel.dismissPermissionAlert() } }
        )
    }

    private var isShowingDeleteResult: Binding<Bool> {
        Binding(
            get: { viewModel.didDeleteAllTasks },
            set: { if !$0 { viewModel.dismissDeleteResult() } }
        )
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }
}
