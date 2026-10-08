import SwiftUI
import UIKit

/// タブバーを標準の位置から少し上に持ち上げる。
///
/// SwiftUI の TabView にはタブバーの位置を指定する手段がなく、余白を足しても画面下端を基準に置かれたままになる。
/// そのため、TabView の中身である UITabBarController の安全領域を広げ、タブバーの基準位置を上にずらしている。
struct TabBarLift: UIViewRepresentable {
    /// 持ち上げる量（pt）
    let amount: CGFloat

    func makeUIView(context _: Context) -> LiftView {
        LiftView(amount: amount)
    }

    func updateUIView(_ uiView: LiftView, context _: Context) {
        uiView.amount = amount
    }

    final class LiftView: UIView {
        var amount: CGFloat {
            didSet {
                guard amount != oldValue else { return }
                appliedController = nil
                applyLiftIfNeeded()
            }
        }

        /// 同じ UITabBarController に何度も設定しないよう、適用済みの相手を覚えておく
        private weak var appliedController: UITabBarController?

        init(amount: CGFloat) {
            self.amount = amount
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            // タブバーはこの背景より後に組み立てられることがあるため、次の更新まで待ってから探す
            DispatchQueue.main.async { [weak self] in
                self?.applyLiftIfNeeded()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            applyLiftIfNeeded()
        }

        private func applyLiftIfNeeded() {
            guard appliedController == nil, let window, let controller = Self.tabBarController(in: window) else {
                return
            }
            controller.additionalSafeAreaInsets.bottom = amount
            appliedController = controller
        }

        /// SwiftUI は UITabBarController を画面の親子関係に公開していないため、
        /// 表示中の UITabBar を探し、そこから持ち主の UITabBarController をたどる
        private static func tabBarController(in view: UIView) -> UITabBarController? {
            if let tabBar = view as? UITabBar {
                return sequence(first: tabBar as UIResponder, next: \.next)
                    .lazy
                    .compactMap { $0 as? UITabBarController }
                    .first
            }
            for subview in view.subviews {
                if let found = tabBarController(in: subview) {
                    return found
                }
            }
            return nil
        }
    }
}
