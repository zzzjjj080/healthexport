import Foundation

/// 表の1行ぶん。日ごとなら1日、週ごと・月ごとならその期間。
struct PeriodRow: Equatable {
    /// 行の先頭に出す印。日は "2026-06-01"、週は "2026-06-01~06-07"、月は "2026-06"
    let label: String
    /// その行に含まれる日数（選んだ期間の内側だけ）。端の週は7日に満たない
    let days: Int
    let values: [MetricID: MetricValue]
}

/// 日ごとの値を、週や月の行にまとめる。
///
/// **まとめた値は「記録のあった日の1日あたり」。** 合計にしないのは、
/// 端の週（3日しかない週）と7日ある週を並べたときに、合計だと比べられないから。
/// 記録の無い日を0として平均に混ぜることもしない（空欄は0ではない、という約束を守る）。
enum Periods {

    static func rows(_ request: ExportRequest) -> [PeriodRow] {
        let days = request.range.days
        switch request.options.grouping {
        case .day:
            return days.map { PeriodRow(label: $0.iso, days: 1, values: request.daily[$0] ?? [:]) }
        case .week, .month:
            var groups: [[YMD]] = []
            for day in days {
                if let last = groups.last?.last, key(last, request.options.grouping) == key(day, request.options.grouping) {
                    groups[groups.count - 1].append(day)
                } else {
                    groups.append([day])
                }
            }
            return groups.map { group in
                var values: [MetricID: MetricValue] = [:]
                for metric in request.metrics {
                    let found = group.compactMap { request.daily[$0]?[metric.id] }
                    if let combined = combine(found, metric: metric) { values[metric.id] = combined }
                }
                return PeriodRow(label: label(group, request.options.grouping), days: group.count, values: values)
            }
        }
    }

    /// 同じ行に入るかを決める鍵。週は月曜はじまり（ISO 8601。国によらず揃える）。
    static func key(_ day: YMD, _ grouping: Grouping) -> String {
        switch grouping {
        case .day:   return day.iso
        case .month: return String(format: "%04d-%02d", day.year, day.month)
        case .week:
            var calendar = Calendar(identifier: .iso8601)
            calendar.timeZone = YMD.calendar.timeZone
            guard let date = calendar.date(from: day.components) else { return day.iso }
            let c = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
        }
    }

    static func label(_ group: [YMD], _ grouping: Grouping) -> String {
        guard let first = group.first, let last = group.last else { return "" }
        switch grouping {
        case .day:   return first.iso
        case .month: return key(first, .month)
        case .week:
            // 年をまたぐ週だけ終わりの年も書く。いつも書くと列が無駄に広がる
            let end = first.year == last.year
                ? String(format: "%02d-%02d", last.month, last.day) : last.iso
            return "\(first.iso)~\(end)"
        }
    }

    /// その期間の値を1つにまとめる。記録が1日も無ければ nil（空欄）。
    static func combine(_ values: [MetricValue], metric: Metric) -> MetricValue? {
        guard !values.isEmpty else { return nil }
        if metric.aggregation == .flowLevel {
            // 生理は平均に意味が無い。出血のあった日数にする（「なし」と記録した日は数えない）
            let bleeding = values.filter {
                if case .localized(let key, _) = $0 { return key != "none" }
                return true
            }.count
            return .dayCount(bleeding)
        }
        let numbers = values.compactMap { value -> Double? in
            if case .number(let v) = value { return v }
            return nil
        }
        if numbers.count == values.count { return .number(mean(numbers)) }

        let stats = values.compactMap { value -> (Double, Double, Double)? in
            if case .stats(let a, let lo, let hi) = value { return (a, lo, hi) }
            return nil
        }
        if stats.count == values.count {
            return .stats(average: mean(stats.map(\.0)),
                          min: stats.map(\.1).min() ?? 0,
                          max: stats.map(\.2).max() ?? 0)
        }

        let sleeps = values.compactMap { value -> SleepSummary? in
            if case .sleep(let s) = value { return s }
            return nil
        }
        if sleeps.count == values.count {
            return .sleep(SleepSummary(
                total: mean(sleeps.map(\.total)), deep: mean(sleeps.map(\.deep)),
                rem: mean(sleeps.map(\.rem)), core: mean(sleeps.map(\.core)),
                awake: mean(sleeps.map(\.awake)),
                bedMinute: meanClock(sleeps.compactMap(\.bedMinute), aroundMidnight: true),
                wakeMinute: meanClock(sleeps.compactMap(\.wakeMinute), aroundMidnight: false)))
        }

        // 気分のような言葉は、いちばん多かったものにする。同数なら後の日のもの
        var counts: [String: Int] = [:]
        var lastSeen: [String: Int] = [:]
        var table: MetricValue.LocalizedTable = .mood
        for (index, value) in values.enumerated() {
            if case .localized(let key, let t) = value {
                counts[key, default: 0] += 1; lastSeen[key] = index; table = t
            }
        }
        if let best = counts.keys.max(by: { (counts[$0]!, lastSeen[$0]!) < (counts[$1]!, lastSeen[$1]!) }) {
            return .localized(key: best, table: table)
        }
        return values.last
    }

    static func mean(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    /// 時刻の平均。就寝は日付をまたぐので、23:30 と 0:30 の平均が 12:00 にならないよう、
    /// 昼より前の時刻に24時間を足してから平均し、戻す。
    static func meanClock(_ minutes: [Int], aroundMidnight: Bool) -> Int? {
        guard !minutes.isEmpty else { return nil }
        let shifted = minutes.map { aroundMidnight && $0 < 12 * 60 ? $0 + 24 * 60 : $0 }
        return Int(mean(shifted.map(Double.init)).rounded()) % (24 * 60)
    }
}
