import Domain
import SwiftUI
import UIKit

/// 設定画面で選んだ外観（ライト / ダーク / 自動）を、アプリのウィンドウに反映する。
///
/// SwiftUI の `preferredColorScheme` では、SwiftUI で描いた背景やカードはすぐ切り替わる一方、
/// UIKit が持つタブバーは別の経路で遅れて切り替わり、切り替わる瞬間がずれる。
/// ウィンドウに直接指定してクロスディゾルブで包み、タブバーを含む画面全体を同時にゆっくり切り替える。
///
/// 切り替え前の画面の写し（`snapshotView` や `drawHierarchy`）を重ねて薄くする方法は、写しの中でガラスの部品が正しく再現されず、
/// 周りの文字がずれて写り込むため使わない
struct WindowAppearance: UIViewRepresentable {
    let mode: AppearanceMode

    func makeUIView(context _: Context) -> AppearanceView {
        AppearanceView(style: mode.userInterfaceStyle)
    }

    func updateUIView(_ uiView: AppearanceView, context _: Context) {
        uiView.style = mode.userInterfaceStyle
    }

    final class AppearanceView: UIView {
        /// 切り替え前の画面から切り替え後の画面へ溶け込ませる時間（秒）
        private static let fadeDuration: TimeInterval = 0.5

        var style: UIUserInterfaceStyle {
            didSet {
                guard style != oldValue else { return }
                apply(animated: true)
            }
        }

        init(style: UIUserInterfaceStyle) {
            self.style = style
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            // 起動直後に保存済みの外観へフェードして見えないよう、最初の指定はすぐに反映する
            apply(animated: false)
        }

        private func apply(animated: Bool) {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            guard animated else {
                window.overrideUserInterfaceStyle = style
                return
            }
            UIView.transition(
                with: window,
                duration: Self.fadeDuration,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                window.overrideUserInterfaceStyle = self.style
            }
        }
    }
}

extension AppearanceMode {
    /// ウィンドウに指定する配色。「自動」は指定しないことで端末の設定に従わせる
    fileprivate var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}
