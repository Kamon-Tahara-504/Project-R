import SwiftUI

/// ホーム上部の日付と昼夜ゲージの表示。分単位で自動更新する
struct DateHeader: View {
    let daylightClock: DaylightClock
    /// 日付と時刻の行の中心の、画面の上端からの高さが変わったときに呼ぶ。背景の梁をこの高さに合わせるため
    var onDateRowMidYChange: (CGFloat) -> Void = { _ in }
    private let calendar = Calendar.current

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(HomeFormatter.dateText(context.date, calendar: calendar))
                    Spacer()
                    daylightGauge(now: context.date)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                // 背景は画面全体に広がっているため、画面を基準にした位置を渡す
                .onGeometryChange(for: CGFloat.self) {
                    $0.frame(in: .global).midY
                } action: {
                    onDateRowMidYChange($0)
                }

                VStack(alignment: .leading, spacing: -16) {
                    Text(HomeFormatter.weekdayAndMonthText(context.date, calendar: calendar))
                        .font(.system(size: 34, weight: .bold))
                    Text(HomeFormatter.dayText(context.date, calendar: calendar))
                        .font(.system(size: 110, weight: .bold))
                }
                .padding(.horizontal, 8)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 4)
        }
    }

    @ViewBuilder
    private func daylightGauge(now: Date) -> some View {
        switch daylightClock {
        case .realTime:
            gauge(at: now)
        case .accelerated:
            // 分単位の更新では早送りの動きが見えないため、毎フレーム描き直す
            TimelineView(.animation) { context in
                gauge(at: daylightClock.date(at: context.date, calendar: calendar))
            }
        }
    }

    private func gauge(at date: Date) -> some View {
        DaylightGauge(
            sky: DaylightCycle.sky(at: date, calendar: calendar),
            skyColor: RoomTintCycle.tint(at: date, calendar: calendar).skyColor,
            timeText: HomeFormatter.gaugeTimeText(date, calendar: calendar)
        )
    }
}

#Preview("実時間") {
    DateHeader(daylightClock: .realTime)
        .padding()
        .background(.gray)
}

#Preview("30 秒で 1 日") {
    DateHeader(daylightClock: .accelerated(secondsPerDay: 30))
        .padding()
        .background(.gray)
}
