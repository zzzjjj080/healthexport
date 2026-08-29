import Foundation

/// 年月日だけを持つ値型。
///
/// `Date` を直接持つと時刻やタイムゾーンで日がずれる。
/// ヘルスケアの「その日の合計」を扱う以上、ここは必ず値型で持つ。
///
/// アキワクの YMD と違い、**タイムゾーンは端末に従う**。
/// このアプリは日本語版と英語版を出すので、Asia/Tokyo に固定してはいけない。
public struct YMD: Hashable, Comparable, Codable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: YMD, rhs: YMD) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// 書き出すテキストの日付。AIにも人にも読める形にする。
    public var iso: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var components: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    public static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    public func date() -> Date? { Self.calendar.date(from: components) }

    /// その日の始まりと、翌日の始まり。HealthKitの期間指定はこの形で渡す。
    public func dayBounds() -> (start: Date, end: Date)? {
        guard let start = date(),
              let end = Self.calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        return (start, end)
    }

    public static func from(_ date: Date) -> YMD {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return YMD(parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public static func today(now: Date = Date()) -> YMD { from(now) }

    public func adding(days: Int) -> YMD {
        guard let base = date(),
              let moved = Self.calendar.date(byAdding: .day, value: days, to: base) else { return self }
        return Self.from(moved)
    }
}

/// 書き出す期間。両端を含む。
public struct DateRange: Equatable, Sendable, Codable {
    public let from: YMD
    public let to: YMD

    public init(from: YMD, to: YMD) {
        // 逆に渡されても壊れないように、ここで揃える
        if from <= to {
            self.from = from
            self.to = to
        } else {
            self.from = to
            self.to = from
        }
    }

    /// 直近 days 日。今日を含む。
    public static func recent(days: Int, today: YMD = .today()) -> DateRange {
        DateRange(from: today.adding(days: -(max(1, days) - 1)), to: today)
    }

    public var days: [YMD] {
        var out: [YMD] = []
        var cursor = from
        while cursor <= to {
            out.append(cursor)
            cursor = cursor.adding(days: 1)
            if out.count > 3000 { break }   // 事故で無限に伸びないための歯止め
        }
        return out
    }

    public var dayCount: Int { days.count }
}
