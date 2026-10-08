import SwiftUI

/// タブで切り替える画面の見出し。画面名と補足を左に、画面ごとの操作を右に置く。
///
/// タブを切り替えたときに画面名の位置や大きさが変わると違和感が出るため、どの画面もこれで見出しを作る。
/// 標準のナビゲーションバーでは補足を画面名の横に添えられないため、自前で組み立てる
public struct ScreenHeader<Trailing: View>: View {
    let title: String
    /// 画面名の右に添える一言（例: 「3件のタスク」）
    let subtitle: String
    /// UI テストから画面名を見つけるための識別子
    let titleIdentifier: String
    @ViewBuilder let trailing: Trailing

    public init(
        title: String,
        subtitle: String,
        titleIdentifier: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleIdentifier = titleIdentifier
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // 大きさの違う文字を下端ではなく文字の並びの線で揃え、ひと続きの見出しに見せる
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(titleIdentifier)
                    .fixedSize()
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    // 補足が長くても画面名や右の操作を押し出さず、補足の側を縮める
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            trailing
        }
        // 右の操作の有無で見出しの高さが変わらないよう、操作のボタンの高さを確保する
        .frame(minHeight: 48)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ScreenHeader(title: "タスク", subtitle: "3件のタスク", titleIdentifier: "preview") {
            Text("締切順")
        }
        ScreenHeader(title: "設定", subtitle: "利用時間 8:00〜20:00", titleIdentifier: "preview")
    }
    .padding()
}
