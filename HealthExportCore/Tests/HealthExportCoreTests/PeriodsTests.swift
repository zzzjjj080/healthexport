import Foundation
import Testing
@testable import HealthExportCore

/// 週・月ごとのまとめ（1.6）。1年ぶんでもチャット欄に貼れる大きさにするためのもの。
struct PeriodsTests {

    static func request(_ grouping: Grouping, metrics: [MetricID],
                        daily: [YMD: [MetricID: MetricValue]],
                        from: YMD = YMD(2026, 6, 1), to: YMD = YMD(2026, 6, 14)) -> ExportRequest {
        var options = ExportOptions(includeAsk: false)
        options.grouping = grouping
        return ExportRequest(range: DateRange(from: from, to: to),
                             metrics: MetricCatalog.metrics(metrics), daily: daily, options: options)
    }

    @Test func 週は月曜はじまりで区切り端の週は日数が少ない() {
        // 2026-06-01 は月曜。06-03(水)〜06-14(日) なら、端の週は5日・次の週は7日
        let rows = Periods.rows(Self.request(.week, metrics: [.steps], daily: [:],
                                             from: YMD(2026, 6, 3), to: YMD(2026, 6, 14)))
        #expect(rows.map(\.label) == ["2026-06-03~06-07", "2026-06-08~06-14"])
        #expect(rows.map(\.days) == [5, 7])
    }

    @Test func 月ごとは年と月で区切る() {
        let rows = Periods.rows(Self.request(.month, metrics: [.steps], daily: [:],
                                             from: YMD(2026, 5, 30), to: YMD(2026, 6, 2)))
        #expect(rows.map(\.label) == ["2026-05", "2026-06"])
        #expect(rows.map(\.days) == [2, 2])
    }

    /// 合計ではなく1日平均。記録の無い日は0として混ぜない（空欄は0ではない、の約束）
    @Test func 値は記録のあった日だけの1日平均() {
        let daily: [YMD: [MetricID: MetricValue]] = [
            YMD(2026, 6, 1): [.steps: .number(6000)],
            YMD(2026, 6, 2): [.steps: .number(10000)],
        ]
        let rows = Periods.rows(Self.request(.week, metrics: [.steps], daily: daily,
                                             from: YMD(2026, 6, 1), to: YMD(2026, 6, 7)))
        #expect(rows.first?.values[.steps] == .number(8000))
    }

    @Test func 心拍は平均の平均と最小の最小と最大の最大() {
        let daily: [YMD: [MetricID: MetricValue]] = [
            YMD(2026, 6, 1): [.heartRate: .stats(average: 70, min: 50, max: 130)],
            YMD(2026, 6, 2): [.heartRate: .stats(average: 80, min: 45, max: 150)],
        ]
        let rows = Periods.rows(Self.request(.week, metrics: [.heartRate], daily: daily,
                                             from: YMD(2026, 6, 1), to: YMD(2026, 6, 7)))
        #expect(rows.first?.values[.heartRate] == .stats(average: 75, min: 45, max: 150))
    }

    /// 23:30 と 0:30 の平均は 0:00。単純に平均すると 12:00 になってしまう
    @Test func 就寝時刻は日付をまたいでも正しく平均する() {
        #expect(Periods.meanClock([23 * 60 + 30, 30], aroundMidnight: true) == 0)
        #expect(Periods.meanClock([6 * 60, 7 * 60], aroundMidnight: false) == 6 * 60 + 30)
    }

    @Test func 生理は出血のあった日数になり_なしの日は数えない() {
        let daily: [YMD: [MetricID: MetricValue]] = [
            YMD(2026, 6, 1): [.menstrualFlow: .localized(key: "medium", table: .flow)],
            YMD(2026, 6, 2): [.menstrualFlow: .localized(key: "light", table: .flow)],
            YMD(2026, 6, 3): [.menstrualFlow: .localized(key: "none", table: .flow)],
        ]
        let rows = Periods.rows(Self.request(.week, metrics: [.menstrualFlow], daily: daily,
                                             from: YMD(2026, 6, 1), to: YMD(2026, 6, 7)))
        #expect(rows.first?.values[.menstrualFlow] == .dayCount(2))
        let text = ExportText.build(Self.request(.week, metrics: [.menstrualFlow], daily: daily,
                                                 from: YMD(2026, 6, 1), to: YMD(2026, 6, 7)))
        #expect(text.contains("2日"))
    }

    @Test func 気分はいちばん多かった言葉() {
        let daily: [YMD: [MetricID: MetricValue]] = [
            YMD(2026, 6, 1): [.stateOfMind: .localized(key: "pleasant", table: .mood)],
            YMD(2026, 6, 2): [.stateOfMind: .localized(key: "neutral", table: .mood)],
            YMD(2026, 6, 3): [.stateOfMind: .localized(key: "pleasant", table: .mood)],
        ]
        let rows = Periods.rows(Self.request(.week, metrics: [.stateOfMind], daily: daily,
                                             from: YMD(2026, 6, 1), to: YMD(2026, 6, 7)))
        #expect(rows.first?.values[.stateOfMind] == .localized(key: "pleasant", table: .mood))
    }

    @Test func 週ごとの表は見出しと日数の列がつく() {
        let daily: [YMD: [MetricID: MetricValue]] = [YMD(2026, 6, 1): [.steps: .number(8000)]]
        let text = ExportText.build(Self.request(.week, metrics: [.steps], daily: daily))
        #expect(text.contains("## 週ごとの記録"))
        #expect(text.contains("week\tdays\t"))
        #expect(text.contains("2026-06-01~06-07\t7\t8000"))
        // 2週目は記録が無いので行ごと省かれる（記録が無い日は省く、が既定）
        #expect(!text.contains("2026-06-08~06-14"))
    }

    /// 1年ぶんの全項目を日ごとで出すと重いが、週ごとなら行数がおよそ 1/7 になる
    @Test func 一年ぶんを週ごとにすると行はおよそ七分の一() {
        var daily: [YMD: [MetricID: MetricValue]] = [:]
        var day = YMD(2025, 9, 22)
        while day <= YMD(2026, 9, 21) { daily[day] = [.steps: .number(8000)]; day = day.adding(days: 1) }
        let byDay = Periods.rows(Self.request(.day, metrics: [.steps], daily: daily,
                                              from: YMD(2025, 9, 22), to: YMD(2026, 9, 21))).count
        let byWeek = Periods.rows(Self.request(.week, metrics: [.steps], daily: daily,
                                               from: YMD(2025, 9, 22), to: YMD(2026, 9, 21))).count
        #expect(byDay == 365)
        #expect(byWeek <= 54)
    }
}

/// 生理は、本人が設定でオンにしたときだけ扱う。
struct CycleOptInTests {

    @Test func 既定ではオフで目的が全部でも入らない() {
        let settings = AppSettings(purpose: .everything)
        #expect(settings.includeCycle == false)
        let ids = settings.effectiveMetrics(available: Set(MetricID.allCases)).map(\.id)
        #expect(!ids.contains(.menstrualFlow))
        #expect(ids.contains(.steps))
    }

    @Test func オンにすると記録があれば入る() {
        let settings = AppSettings(purpose: .everything, includeCycle: true)
        #expect(settings.effectiveMetrics(available: Set(MetricID.allCases)).map(\.id).contains(.menstrualFlow))
    }

    @Test func 自分で項目を選んでいてもオフなら入らない() {
        let settings = AppSettings(customMetrics: [.menstrualFlow, .steps])
        #expect(settings.effectiveMetrics(available: Set(MetricID.allCases)).map(\.id) == [.steps])
    }

    @Test func 古い設定を読むとオフで週まとめは日ごと() throws {
        let old = #"{"purpose":"general","options":{"language":"ja"}}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(AppSettings.self, from: old)
        #expect(settings.includeCycle == false)
        #expect(settings.options.grouping == .day)
    }
}
