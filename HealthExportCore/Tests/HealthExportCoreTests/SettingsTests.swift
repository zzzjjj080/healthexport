import Foundation
import Testing
@testable import HealthExportCore

struct DateRangeTests {

    @Test func 直近90日は両端を含んで90日になる() {
        let range = DateRange.recent(days: 90, today: YMD(2026, 8, 29))
        #expect(range.from == YMD(2026, 6, 1))
        #expect(range.to == YMD(2026, 8, 29))
        #expect(range.dayCount == 90)
    }

    @Test func 逆に渡しても期間として成り立つ() {
        let range = DateRange(from: YMD(2026, 8, 29), to: YMD(2026, 6, 1))
        #expect(range.from == YMD(2026, 6, 1))
        #expect(range.to == YMD(2026, 8, 29))
    }

    @Test func 月をまたいでも日付が飛ばない() {
        let range = DateRange(from: YMD(2026, 1, 30), to: YMD(2026, 3, 2))
        let days = range.days
        #expect(days.contains(YMD(2026, 2, 28)))
        #expect(!days.contains(YMD(2026, 2, 29)))   // 2026年は閏年ではない
        #expect(days.count == 32)
    }

    @Test func 同じ日を指定すると1日になる() {
        let range = DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 6, 1))
        #expect(range.dayCount == 1)
    }
}

struct AppSettingsTests {

    @Test func 目的を選ぶだけで期間が決まる() {
        let today = YMD(2026, 8, 29)
        #expect(AppSettings(purpose: .general).effectiveRange(today: today).dayCount == 90)
        #expect(AppSettings(purpose: .condition).effectiveRange(today: today).dayCount == 30)
        #expect(AppSettings(purpose: .sleep).effectiveRange(today: today).dayCount == 60)
    }

    @Test func 日付を直に指定するとそちらが優先される() {
        let range = DateRange(from: YMD(2026, 1, 1), to: YMD(2026, 1, 10))
        let settings = AppSettings(purpose: .general, customDays: 30, customRange: range)
        #expect(settings.effectiveRange(today: YMD(2026, 8, 29)) == range)
    }

    @Test func 記録が無い項目は選ばれていても外れる() {
        // 「選んだのに空の列が並ぶ」ほうが紛らわしい
        let settings = AppSettings(purpose: .general)
        let available: Set<MetricID> = [.steps, .sleep]
        let metrics = settings.effectiveMetrics(available: available)
        #expect(metrics.map(\.id) == [.steps, .sleep])
    }

    @Test func 全部渡すを選ぶと記録がある項目がすべて入る() {
        let settings = AppSettings(purpose: .everything)
        let available: Set<MetricID> = [.steps, .headphoneAudio, .mindful]
        #expect(settings.effectiveMetrics(available: available).count == 3)
    }

    @Test func 列の順はどの目的でも同じになる() {
        // 目的ごとに列順が変わると、前の書き出しと読み比べられない
        let available = Set(MetricID.allCases)
        let general = AppSettings(purpose: .general).effectiveMetrics(available: available).map(\.id)
        let sleep = AppSettings(purpose: .sleep).effectiveMetrics(available: available).map(\.id)
        let catalog = MetricCatalog.all.map(\.id)
        #expect(general == catalog.filter { general.contains($0) })
        #expect(sleep == catalog.filter { sleep.contains($0) })
    }

    @Test func 自分で選んだ項目は目的より優先される() {
        let settings = AppSettings(purpose: .sleep, customMetrics: [.steps])
        #expect(settings.effectiveMetrics(available: Set(MetricID.allCases)).map(\.id) == [.steps])
    }
}

struct SettingsCodableTests {

    /// 設定に項目を1つ足しただけで、それまでの設定が丸ごと読めなくなるのを防ぐ。
    /// `decode` は1つでも欠けると nil を返すので、**旧版のJSONを直書きしたテストを必ず置く。**
    @Test func 項目が足りない古い設定でも既定値で読める() throws {
        let old = """
        {"purpose":"training","options":{"language":"en","separator":"comma"}}
        """.data(using: .utf8)!
        let settings = try JSONDecoder().decode(AppSettings.self, from: old)
        #expect(settings.purpose == .training)
        #expect(settings.options.language == .en)
        #expect(settings.options.separator == .comma)
        // 無かったものは既定値で埋まる
        #expect(settings.options.layout == .wide)
        #expect(settings.options.includeAsk == true)
        #expect(settings.options.skipEmptyDays == true)
        #expect(settings.options.rawMetrics.isEmpty)
        #expect(settings.customMetrics == nil)
    }

    @Test func 空の設定でも落ちない() throws {
        let settings = try JSONDecoder().decode(AppSettings.self, from: "{}".data(using: .utf8)!)
        #expect(settings.purpose == .general)
        #expect(settings.options == ExportOptions())
    }

    @Test func 書いて読み直すと同じものになる() throws {
        var options = ExportOptions()
        options.rawMetrics = [.heartRate, .sleep]
        options.shortColumnNames = true
        let original = AppSettings(purpose: .condition, customDays: 45,
                                   customMetrics: [.steps, .sleep], options: options)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(restored == original)
    }

    @Test func 知らない項目が入っていても読める() throws {
        // 新しい版で足した設定が入った状態で、古い版に戻したときのため
        let future = """
        {"purpose":"general","futureFlag":true,"options":{"language":"ja","unknown":123}}
        """.data(using: .utf8)!
        let settings = try JSONDecoder().decode(AppSettings.self, from: future)
        #expect(settings.purpose == .general)
    }
}

struct ClockLabelTests {

    @Test func 分を時刻の表記にする() {
        #expect(clockLabel(0) == "00:00")
        #expect(clockLabel(9 * 60 + 5) == "09:05")
        #expect(clockLabel(23 * 60 + 59) == "23:59")
    }

    @Test func 時刻は24時間を超えた分を翌日として折り返す() {
        // 就寝が22:30で睡眠が続くと、区間の終わりが1440分を超える
        #expect(clockLabel(1440) == "00:00")
        #expect(clockLabel(1440 + 390) == "06:30")
    }

    @Test func 負の分でも壊れない() {
        #expect(clockLabel(-60) == "23:00")
    }
}

struct DeviceNameTests {

    /// ヘルスケアの端末名には「〇〇のApple Watch」のように本名が入っていることが多い。
    /// AIに渡すテキストなので、外せることをここで保証しておく。
    @Test func 端末名を外すと本文に残らない() {
        var options = ExportOptions(includeAsk: false)
        options.includeDeviceNames = false
        let request = ExportRequest(range: DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 6, 1)),
                                    metrics: MetricCatalog.metrics([.steps]),
                                    daily: [YMD(2026, 6, 1): [.steps: .number(100)]],
                                    devices: ["仁のApple Watch", "iPhone Air"],
                                    options: options)
        let text = ExportText.build(request)
        #expect(!text.contains("仁"))
        #expect(!text.contains("iPhone Air"))
        #expect(text.contains("（記載しない）"))
    }

    @Test func 既定では端末名が入る() {
        let request = ExportRequest(range: DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 6, 1)),
                                    metrics: MetricCatalog.metrics([.steps]),
                                    daily: [YMD(2026, 6, 1): [.steps: .number(100)]],
                                    devices: ["iPhone Air"],
                                    options: ExportOptions(includeAsk: false))
        #expect(ExportText.build(request).contains("iPhone Air"))
    }
}

struct DefaultPurposeTests {

    /// 既定は「記録があるものを全部」。
    /// 何が役に立つかは渡してみないと分からないので、選ぶ手間をかけさせない。
    @Test func ふだんの管理は記録がある項目をすべて選ぶ() {
        let settings = AppSettings()
        #expect(settings.purpose == .general)
        let available: Set<MetricID> = [.steps, .sleep, .headphoneAudio, .mindful, .walkingSpeed]
        #expect(settings.effectiveMetrics(available: available).count == 5)
    }

    /// 全項目でも、日ごとにまとめてあればチャット欄に貼れる量におさまる。
    @Test func 全項目を90日ぶん出しても貼れる大きさにおさまる() {
        let range = DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 8, 29))
        var daily: [YMD: [MetricID: MetricValue]] = [:]
        for day in range.days {
            var row: [MetricID: MetricValue] = [:]
            for metric in MetricCatalog.all {
                switch metric.aggregation {
                case .workoutList: continue
                case .sleep:
                    row[metric.id] = .sleep(SleepSummary(total: 7.2, deep: 1.1, rem: 1.5, core: 4.6,
                                                         awake: 0.3, bedMinute: 1350, wakeMinute: 400))
                case .minMaxAverage:
                    row[metric.id] = .stats(average: 72, min: 50, max: 140)
                case .moodLatest:
                    row[metric.id] = .text("ふつう")
                default:
                    row[metric.id] = .number(1234.5)
                }
            }
            daily[day] = row
        }
        let text = ExportText.build(ExportRequest(range: range, metrics: MetricCatalog.all,
                                                  daily: daily, purpose: .general))
        let estimate = SizeEstimate.of(text)
        #expect(estimate.verdict == .comfortable)
        #expect(estimate.approximateTokens < 30_000)
    }
}
