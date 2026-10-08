import SwiftUI

/// 時刻に合わせて空の色に染まる長円形のゲージ。中央に太陽（夜は月）と時刻を並べて表示する
struct DaylightGauge: View {
    let sky: SkyState
    /// ゲージの背景色。朝焼け・夕焼けで部屋の背景と揃うよう、`RoomTint.skyColor` を渡す
    let skyColor: Color
    /// ゲージ内に表示する時刻（例: 「9:41」）
    let timeText: String

    private let width: CGFloat = 120
    private let height: CGFloat = 26
    /// 太陽（17pt）と月（16pt）で幅が違い、切り替え時に位置がずれるため、広い方に合わせて固定する
    private let iconWidth: CGFloat = 18
    /// 時刻の表示幅を決めるための最も長い時刻。3 桁（9:59）と 4 桁（10:00）で幅が変わると、中央寄せのアイコンごと左右にずれるため
    private static let widestTimeText = "00:00"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: sky.body == .sun ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SkyPalette.nightIcon.mix(with: SkyPalette.dayIcon, by: sky.daylight))
                .frame(width: iconWidth)
            // 固定の数値ではなく見えない最長の時刻で幅を確保し、文字サイズの設定が変わっても幅が追従するようにしている
            ZStack(alignment: .leading) {
                timeLabel(Self.widestTimeText)
                    .hidden()
                timeLabel(timeText)
            }
        }
        .frame(width: width, height: height)
        .background {
            ZStack {
                skyColor
                SkyDecoration(cloudVisibility: sky.cloudVisibility)
            }
            .clipShape(Capsule())
        }
        .overlay(Capsule().strokeBorder(.white.opacity(0.8), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(sky.body == .sun ? "日中" : "夜間") \(timeText)")
    }

    private func timeLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.white)
    }
}

private enum SkyPalette {
    /// 月: 白寄りの黄色
    static let nightIcon = Color(red: 1.00, green: 0.96, blue: 0.75)
    /// 太陽: オレンジ
    static let dayIcon = Color(red: 1.00, green: 0.55, blue: 0.10)
}

#Preview {
    let calendar = Calendar.current
    VStack(spacing: 16) {
        ForEach([0, 6, 12, 17, 18, 19], id: \.self) { hour in
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
            DaylightGauge(
                sky: DaylightCycle.sky(at: date, calendar: calendar),
                skyColor: RoomTintCycle.tint(at: date, calendar: calendar).skyColor,
                timeText: "\(hour):00"
            )
        }
    }
    .padding()
    .background(.gray)
}
