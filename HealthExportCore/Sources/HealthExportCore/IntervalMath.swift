import Foundation

/// 時間の区間をまとめる計算。
///
/// 睡眠は iPhone と Apple Watch が**両方とも記録する**ことがあり、
/// そのまま足すと2倍近い睡眠時間になる。重なりを潰してから数える。
public enum IntervalMath {

    public struct Interval: Equatable, Sendable {
        public let start: Date
        public let end: Date
        public init(start: Date, end: Date) {
            // 逆に来ても壊れないようにする
            self.start = min(start, end)
            self.end = max(start, end)
        }
        public var minutes: Double { end.timeIntervalSince(start) / 60 }
    }

    /// 重なりを潰した区間。開始の早い順に並ぶ。
    public static func merged(_ intervals: [Interval]) -> [Interval] {
        let sorted = intervals.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        var result: [Interval] = []
        for interval in sorted {
            if let last = result.last, interval.start <= last.end {
                result[result.count - 1] = Interval(start: last.start, end: max(last.end, interval.end))
            } else {
                result.append(interval)
            }
        }
        return result
    }

    /// 重なりを潰したうえでの合計（分）。
    public static func totalMinutes(_ intervals: [Interval]) -> Double {
        merged(intervals).reduce(0) { $0 + $1.minutes }
    }

    public static func earliestStart(_ intervals: [Interval]) -> Date? {
        intervals.map(\.start).min()
    }

    public static func latestEnd(_ intervals: [Interval]) -> Date? {
        intervals.map(\.end).max()
    }
}
