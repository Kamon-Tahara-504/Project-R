import SwiftUI
import UIKit

/// 指定したタブが選ばれている間だけ、そのタブを色の付いた長円のボタンにし、文字とアイコンを白くする。
///
/// SwiftUI の TabView にはタブごとに選択中の見た目を変える手段がなく、
/// iOS 26 のタブバーは選択中の背景の色や画像の指定も無視するため、タブバーの上に自前の長円を重ねる。
/// タブを載せたガラスの板の中に置くと板の色の効果で色が変わるため、板の外側（タブバー本体）に置き、
/// アイコンと文字はタブバー自身の部品から写して位置と大きさを揃える。
///
/// OS 内部の構成に頼るため、構成が変わって部品が見つからなくなった場合は、標準の見た目のまま表示される
struct TabBarItemHighlight: UIViewRepresentable {
    /// 見た目を変えるタブの位置（左から 0 始まり）
    let index: Int
    /// 長円の色
    let color: UIColor
    /// そのタブが選ばれているか
    let isSelected: Bool

    func makeUIView(context _: Context) -> HighlightView {
        HighlightView(index: index, color: color)
    }

    func updateUIView(_ uiView: HighlightView, context _: Context) {
        uiView.isTargetSelected = isSelected
    }

    final class HighlightView: UIView {
        /// 選択の切り替えで、長円を出し入れする時間（秒）
        private static let fadeDuration: TimeInterval = 0.2

        private let index: Int
        private let overlay: CapsuleButtonOverlay

        var isTargetSelected = false {
            didSet {
                guard isTargetSelected != oldValue else { return }
                // 選択が変わると SwiftUI がタブの名前やアイコンを差し替えるため、差し替え後に写し直す
                DispatchQueue.main.async { [weak self] in
                    self?.placeOverlay()
                    self?.updateOverlayVisibility(animated: true)
                }
            }
        }

        init(index: Int, color: UIColor) {
            self.index = index
            overlay = CapsuleButtonOverlay(color: color)
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
                self?.placeOverlay()
                self?.updateOverlayVisibility(animated: false)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            placeOverlay()
        }

        private func updateOverlayVisibility(animated: Bool) {
            let alpha: CGFloat = isTargetSelected ? 1 : 0
            guard animated else {
                overlay.alpha = alpha
                return
            }
            UIView.animate(withDuration: Self.fadeDuration) { self.overlay.alpha = alpha }
        }

        /// 長円を対象のタブの真上に置き、そのタブのアイコンと文字を写す
        private func placeOverlay() {
            guard let window,
                let tabBar = TabBarViews.first(in: window, where: { $0 is UITabBar }) as? UITabBar,
                let button = TabBarViews.button(at: index, of: tabBar)
            else { return }
            if overlay.superview !== tabBar {
                tabBar.addSubview(overlay)
            } else {
                tabBar.bringSubviewToFront(overlay)
            }
            overlay.frame = button.convert(button.bounds, to: tabBar)
            overlay.copyContent(from: button)
        }
    }
}

/// 選択中のタブの上に重ねる、色の付いた長円と白いアイコン・文字。
/// 押す操作は下のタブに通すため、触れても反応しない
private final class CapsuleButtonOverlay: UIView {
    private let imageView = UIImageView()
    private let label = UILabel()

    init(color: UIColor) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = color
        layer.cornerCurve = .continuous
        alpha = 0
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        label.textColor = .white
        label.textAlignment = .center
        addSubview(imageView)
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func copyContent(from button: UIView) {
        if let sourceImage = button.subviews.compactMap({ $0 as? UIImageView }).first {
            imageView.image = sourceImage.image?.withRenderingMode(.alwaysTemplate)
            imageView.frame = sourceImage.frame
        }
        if let sourceLabel = button.subviews.compactMap({ $0 as? UILabel }).first {
            label.text = sourceLabel.text
            label.font = sourceLabel.font
            label.frame = sourceLabel.frame
        }
    }
}

/// タブバー内部の部品を探す。部品の種類は公開されていないため、クラス名と並び順で見分ける
private enum TabBarViews {
    static func first(in view: UIView, where matches: (UIView) -> Bool) -> UIView? {
        if matches(view) {
            return view
        }
        for subview in view.subviews {
            if let found = first(in: subview, where: matches) {
                return found
            }
        }
        return nil
    }

    /// 通常表示のタブを並べた層から、左から `index` 番目のボタンを返す。
    /// 選択中の見た目を並べた別の層もあるため、ガラスの板（PlatterView）直下の層に絞る
    static func button(at index: Int, of tabBar: UITabBar) -> UIView? {
        let layer = first(in: tabBar) { view in
            // 入れ子の型は短い名前だけでは区別できないため、親の型名を含む正式なクラス名で見分ける
            let className = NSStringFromClass(type(of: view))
            return className.contains("PlatterView") && className.contains("ContentView")
                && view.subviews.contains { $0 is UIControl }
        }
        let buttons = layer?.subviews.filter { $0 is UIControl } ?? []
        return buttons.indices.contains(index) ? buttons[index] : nil
    }
}
