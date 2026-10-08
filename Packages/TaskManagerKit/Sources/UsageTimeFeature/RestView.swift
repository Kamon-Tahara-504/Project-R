import SwiftUI

/// 利用時間外に表示する休憩画面。
///
/// 締め出すのではなく、ひと呼吸おいてから本人の意思で確認できるようにする。
public struct RestView: View {
    /// 例: 「8:00〜20:00」
    private let availableHoursText: String
    private let onConfirm: () -> Void

    @State private var isConfirming = false

    public init(availableHoursText: String, onConfirm: @escaping () -> Void) {
        self.availableHoursText = availableHoursText
        self.onConfirm = onConfirm
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
            Text("今は休む時間です")
                .font(.title2.bold())
            Text("タスクを確認できるのは \(availableHoursText) です")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Button("タスクを確認する") {
                isConfirming = true
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityIdentifier("restConfirmButton")
        }
        .foregroundStyle(.white)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .alert("本当にタスクを確認しますか？", isPresented: $isConfirming) {
            Button("確認する", action: onConfirm)
            Button("休む", role: .cancel) {}
        } message: {
            Text("今は休むと決めた時間です。")
        }
    }
}

#Preview {
    RestView(availableHoursText: "8:00〜20:00", onConfirm: {})
}
