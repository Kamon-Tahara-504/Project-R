import SwiftUI

/// リキッドグラスの背景と影。アプリの部品の見た目をこれで揃える。
///
/// iOS 26 より前は、近い見た目の半透明の素材で代わりに描く
private struct GlassBackground<S: Shape>: ViewModifier {
    let shape: S
    /// ガラスに重ねる色。`nil` なら色を付けない
    let tint: Color?
    /// 押したときにガラスが反応するか。入力欄のように押しても何も起きない部品では切る
    let isInteractive: Bool

    func body(content: Content) -> some View {
        glass(content)
            // 影を中身に掛けると文字にも影が付くため、ガラスの下に敷いた同じ形にだけ掛ける
            .background {
                shape
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            }
    }

    @ViewBuilder
    private func glass(_ content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(Glass.regular.tint(tint).interactive(isInteractive), in: shape)
        } else {
            content.background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint {
                        shape.fill(tint)
                    }
                }
            }
        }
    }
}

extension View {
    /// リキッドグラスの背景と影を付ける
    public func glassBackground<S: Shape>(in shape: S, tint: Color? = nil, isInteractive: Bool = true) -> some View {
        modifier(GlassBackground(shape: shape, tint: tint, isInteractive: isInteractive))
    }
}
