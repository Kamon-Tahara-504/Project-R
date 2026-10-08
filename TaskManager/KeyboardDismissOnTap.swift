import SwiftUI
import UIKit

/// 入力欄以外の場所をタップしたらキーボードを閉じる。
///
/// シートやアラートを含む全画面で効くよう、画面ごとではなくウィンドウにジェスチャーを登録する
struct KeyboardDismissOnTap: UIViewRepresentable {
    func makeUIView(context _: Context) -> InstallerView {
        InstallerView()
    }

    func updateUIView(_: InstallerView, context _: Context) {}

    final class InstallerView: UIView, UIGestureRecognizerDelegate {
        private lazy var recognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            // キーボードを閉じつつ、ボタンやリストのタップもそのまま届ける
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            return recognizer
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, recognizer.view !== window else { return }
            recognizer.view?.removeGestureRecognizer(recognizer)
            window.addGestureRecognizer(recognizer)
        }

        @objc private func dismissKeyboard() {
            window?.endEditing(true)
        }

        /// 別の入力欄をタップしたときは、その入力欄へ切り替えたいのでキーボードを閉じない
        func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            !Self.isInsideTextInput(touch.view)
        }

        /// 画面側のタップやスクロールの認識を妨げないよう、同時に認識させる
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private static func isInsideTextInput(_ view: UIView?) -> Bool {
            var current = view
            while let candidate = current {
                if candidate is UITextField || candidate is UITextView {
                    return true
                }
                current = candidate.superview
            }
            return false
        }
    }
}
