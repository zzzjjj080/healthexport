import Foundation
import Testing
@testable import HealthExportCore

/// 書き出したテキストの形。**AIにも人にも読める1枚**であることを、ここで固定する。
struct ExportTextTests {

    // MARK: - 材料

    static let day1 = YMD(2026, 6, 1)
    static let day3 = YMD(2026, 6, 3)

    static func request(
        metrics: [MetricID] = [.steps, .heartRate, .sleep],
        options: ExportOptions = ExportOptions(includeAsk: false),
        daily: [YMD: [MetricID: MetricValue]]? = nil,
        workouts: [WorkoutEvent] = [],
        rawSeries: [MetricID: RawSeries] = [:]
    ) -> ExportRequest {
        let range = DateRange(from: day1, to: day3)
        let filled: [YMD: [MetricID: MetricValue]] = daily ?? [
            day1: [.steps: .number(8432),
                   .heartRate: .stats(average: 72, min: 48, max: 131),
                   .sleep: .sleep(SleepSummary(total: 7.4, deep: 1.1, rem: 1.6, core: 4.7, awake: 0.4,
                                               bedMinute: 22 * 60 + 32, wakeMinute: 6 * 60 + 15))],
            YMD(2026, 6, 2): [.steps: .number(10233),
                              .heartRate: .stats(average: 74, min: 51, max: 152)],
            day3: [.steps: .number(6021)],
        ]
        return ExportRequest(range: range,
                             metrics: MetricCatalog.metrics(metrics),
                             daily: filled,
                             workouts: workouts,
                             rawSeries: rawSeries,
                             devices: ["iPhone Air", "Apple Watch"],
                             purpose: .general,
                             options: options,
                             exportedAt: Date(timeIntervalSince1970: 1_780_000_000))
    }

    static func lines(_ text: String) -> [String] { text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) }
    static func dataRows(_ text: String) -> [String] {
        lines(text).filter { $0.range(of: "^\\d{4}-\\d{2}-\\d{2}\t", options: .regularExpression) != nil }
    }

    // MARK: - 骨組み

    @Test func 日ごとの表は期間ぶんの行になる() {
        let text = ExportText.build(Self.request(options: ExportOptions(includeAsk: false, skipEmptyDays: false)))
        let rows = Self.dataRows(text)
        #expect(rows.count == 3)
        #expect(rows.first?.hasPrefix("2026-06-01") == true)
        #expect(rows.last?.hasPrefix("2026-06-03") == true)
    }

    @Test func 記録が無い日は既定で行ごと省く() {
        let daily: [YMD: [MetricID: MetricValue]] = [Self.day1: [.steps: .number(100)]]
        let text = ExportText.build(Self.request(metrics: [.steps], daily: daily))
        #expect(Self.dataRows(text).count == 1)

        let kept = ExportText.build(Self.request(metrics: [.steps],
                                                 options: ExportOptions(includeAsk: false, skipEmptyDays: false),
                                                 daily: daily))
        #expect(Self.dataRows(kept).count == 3)
    }

    @Test func 心拍は平均と最小と最大の3列に開く() {
        let text = ExportText.build(Self.request(metrics: [.heartRate]))
        let head = Self.lines(text).first { $0.hasPrefix("date") }!
        #expect(head == "date\t心拍数(平均)\t心拍数(最小)\t心拍数(最大)")
        let row = Self.dataRows(text).first!
        #expect(row == "2026-06-01\t72\t48\t131")
    }

    @Test func 睡眠は合計と内訳と就寝起床に開く() {
        let text = ExportText.build(Self.request(metrics: [.sleep]))
        let head = Self.lines(text).first { $0.hasPrefix("date") }!
        #expect(head.contains("睡眠(合計)"))
        #expect(head.contains("睡眠(就寝)"))
        let row = Self.dataRows(text).first!
        #expect(row == "2026-06-01\t7.4\t1.1\t1.6\t4.7\t22:32\t06:15")
    }

    @Test func 値が無い項目の列は空欄で埋まり列数はそろう() {
        // 6/3 は歩数しかない。列がずれるとAIが読み違える
        let text = ExportText.build(Self.request(options: ExportOptions(includeAsk: false, skipEmptyDays: false)))
        let rows = Self.dataRows(text)
        let headCount = Self.lines(text).first { $0.hasPrefix("date") }!.components(separatedBy: "\t").count
        for row in rows {
            #expect(row.components(separatedBy: "\t").count == headCount)
        }
    }

    @Test func 桁数は項目ごとの決まりに従う() {
        let daily: [YMD: [MetricID: MetricValue]] = [Self.day1: [.steps: .number(8432.6), .distance: .number(6.3456)]]
        let text = ExportText.build(Self.request(metrics: [.steps, .distance], daily: daily))
        #expect(Self.dataRows(text).first == "2026-06-01\t8433\t6.35")
    }

    // MARK: - 言語と列名

    @Test func 英語にすると見出しも列名も睡眠の段階も英語になる() {
        var options = ExportOptions(includeAsk: false)
        options.language = .en
        let text = ExportText.build(Self.request(options: options))
        #expect(text.contains("# Health data export"))
        #expect(text.contains("Period: 2026-06-01 to 2026-06-03 (3 days)"))
        #expect(text.contains("## Daily values"))
        #expect(text.contains("Heart rate(avg)"))
        #expect(!text.contains("日ごとの記録"))
    }

    @Test func 列名を短くすると凡例が付く() {
        var options = ExportOptions(includeAsk: false)
        options.shortColumnNames = true
        let text = ExportText.build(Self.request(options: options))
        #expect(text.contains("## 列の意味"))
        #expect(text.contains("hr_avg, hr_min, hr_max = 心拍数 (bpm)"))
        let head = Self.lines(text).first { $0.hasPrefix("date") }!
        #expect(head.contains("hr_avg"))
        #expect(!head.contains("心拍数"))
    }

    /// 90日ぶんの材料。長い期間でどうなるかを見るときに使う。
    static func longRequest(options: ExportOptions) -> ExportRequest {
        let range = DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 8, 29))
        var daily: [YMD: [MetricID: MetricValue]] = [:]
        for (index, day) in range.days.enumerated() {
            daily[day] = [.steps: .number(Double(7000 + index * 7)),
                          .heartRate: .stats(average: 70, min: 50, max: 130),
                          .sleep: .sleep(SleepSummary(total: 7.2, deep: 1.1, rem: 1.5, core: 4.6, awake: 0.3,
                                                      bedMinute: 1350, wakeMinute: 400))]
        }
        return ExportRequest(range: range,
                             metrics: MetricCatalog.metrics([.steps, .heartRate, .sleep]),
                             daily: daily, options: options)
    }

    /// **列名を短くしても本文は小さくならない。**
    ///
    /// 列名は表の1行目にしか出ないのに、凡例は項目の数だけ増えるため、
    /// 90日ぶんで測っても短縮版のほうがわずかに大きい。
    /// 画面で「短くなる」と説明してはいけない。実際に小さくなるのは
    /// 期間・項目数・説明文の量を減らしたときだけ。
    @Test func 列名を短くしても本文はむしろわずかに増える() {
        var short = ExportOptions(includeAsk: false)
        short.shortColumnNames = true
        let plain = ExportOptions(includeAsk: false)

        let longPlain = SizeEstimate.of(ExportText.build(Self.longRequest(options: plain))).approximateTokens
        let longShort = SizeEstimate.of(ExportText.build(Self.longRequest(options: short))).approximateTokens
        #expect(longShort > longPlain)
        #expect(Double(longShort) < Double(longPlain) * 1.05)   // 差はごくわずか
    }

    @Test func 本文を小さくするのは期間と項目数と説明文の量() {
        let base = ExportOptions(includeAsk: false)
        let full = SizeEstimate.of(ExportText.build(Self.longRequest(options: base))).approximateTokens

        var noHeader = base
        noHeader.header = .none
        #expect(SizeEstimate.of(ExportText.build(Self.longRequest(options: noHeader))).approximateTokens < full)

        // 項目を減らす
        let range = DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 8, 29))
        let fewer = ExportRequest(range: range, metrics: MetricCatalog.metrics([.steps]),
                                  daily: Self.longRequest(options: base).daily, options: base)
        #expect(SizeEstimate.of(ExportText.build(fewer)).approximateTokens < full)

        // 期間を短くする
        let shorter = ExportRequest(range: DateRange(from: YMD(2026, 8, 1), to: YMD(2026, 8, 29)),
                                    metrics: MetricCatalog.metrics([.steps, .heartRate, .sleep]),
                                    daily: Self.longRequest(options: base).daily, options: base)
        #expect(SizeEstimate.of(ExportText.build(shorter)).approximateTokens < full)
    }

    // MARK: - 依頼文

    @Test func 依頼文は先頭に入り断りの一文で終わる() {
        var options = ExportOptions()
        options.includeAsk = true
        let text = ExportText.build(Self.request(options: options))
        #expect(text.hasPrefix("以下は私のiPhoneのヘルスケアに記録されている"))
        #expect(text.contains("これは医療的な診断のためのものではありません"))
        // データより前に置く。長い表の後ろだと指示が埋もれる
        let askIndex = text.range(of: "医療的な診断")!.lowerBound
        let tableIndex = text.range(of: "## 日ごとの記録")!.lowerBound
        #expect(askIndex < tableIndex)
    }

    @Test func 依頼文を外すと本文だけになる() {
        let text = ExportText.build(Self.request(options: ExportOptions(includeAsk: false)))
        #expect(text.hasPrefix("# ヘルスケアの記録"))
    }

    @Test func 説明文を無しにすると見出しごと消える() {
        var options = ExportOptions(includeAsk: false)
        options.header = .none
        let text = ExportText.build(Self.request(options: options))
        #expect(!text.contains("# ヘルスケアの記録"))
        #expect(text.hasPrefix("## 日ごとの記録"))
    }

    @Test func 最小限の説明文では期間だけ残る() {
        var options = ExportOptions(includeAsk: false)
        options.header = .minimal
        let text = ExportText.build(Self.request(options: options))
        #expect(text.contains("期間: 2026-06-01"))
        #expect(!text.contains("記録した端末"))
    }

    // MARK: - 区切り

    @Test func カンマ区切りで値にカンマが混ざっても列がずれない() {
        var options = ExportOptions(includeAsk: false)
        options.separator = .comma
        let workout = WorkoutEvent(day: Self.day1, startMinute: 7 * 60, minutes: 45,
                                   kilocalories: 320, averageHeartRate: 128,
                                   kindJa: "筋力トレーニング, 上半身", kindEn: "Strength, upper body")
        let text = ExportText.build(Self.request(metrics: [.workouts], options: options, workouts: [workout]))
        let row = Self.lines(text).first { $0.hasPrefix("2026-06-01") }!
        #expect(row.contains("\"筋力トレーニング, 上半身\""))
        #expect(row.components(separatedBy: "\"").count == 3)   // 引用符は1組だけ
    }

    @Test func 見やすく揃える指定では等幅で桁がそろう() {
        var options = ExportOptions(includeAsk: false)
        options.separator = .aligned
        let text = ExportText.build(Self.request(metrics: [.steps], options: options))
        let rows = Self.lines(text).filter { $0.hasPrefix("2026-") }
        // 数字の開始位置が全行でそろっていること
        let positions = rows.map { $0.range(of: "  ")!.upperBound.utf16Offset(in: $0) }
        #expect(Set(positions).count == 1)
    }

    // MARK: - ワークアウト

    @Test func ワークアウトが無い期間でも見出しは出す() {
        let text = ExportText.build(Self.request(metrics: [.workouts]))
        #expect(text.contains("## ワークアウト"))
        #expect(text.contains("（この期間に記録なし）"))
    }

    @Test func 期間の外のワークアウトは混ざらない() {
        let inside = WorkoutEvent(day: Self.day1, startMinute: 420, minutes: 30, kindJa: "散歩", kindEn: "Walk")
        let outside = WorkoutEvent(day: YMD(2026, 5, 30), startMinute: 420, minutes: 30, kindJa: "散歩", kindEn: "Walk")
        let text = ExportText.build(Self.request(metrics: [.workouts], workouts: [inside, outside]))
        #expect(text.contains("## ワークアウト（1）"))
        #expect(!text.contains("2026-05-30"))
    }

    // MARK: - 1件ずつ全部

    @Test func 詳細にした項目は日ごとの表から外れて別のまとまりになる() {
        var options = ExportOptions(includeAsk: false)
        options.rawMetrics = [.heartRate]
        let samples = (0..<5).map { RawSample(day: Self.day1, minute: $0 * 60, value: 70 + Double($0)) }
        let text = ExportText.build(Self.request(options: options, rawSeries: [.heartRate: .numbers(samples)]))
        let head = Self.lines(text).first { $0.hasPrefix("date") }!
        #expect(!head.contains("心拍数"))            // 日ごとの表には出ない
        #expect(text.contains("## 心拍数（bpm） 詳細（全 5 件）"))
        #expect(text.contains("2026-06-01 04:00\t74"))
    }

    @Test func 睡眠の詳細は区間の一覧になる() {
        var options = ExportOptions(includeAsk: false)
        options.rawMetrics = [.sleep]
        let segments = [SleepSegment(day: Self.day1, startMinute: 22 * 60, endMinute: 23 * 60,
                                     stageJa: "コア", stageEn: "core")]
        let text = ExportText.build(Self.request(metrics: [.sleep], options: options,
                                                 rawSeries: [.sleep: .sleepSegments(segments)]))
        #expect(text.contains("開始\t終了\t段階"))
        #expect(text.contains("2026-06-01 22:00\t23:00\tコア"))
    }

    // MARK: - 項目ごとに分ける形

    @Test func 項目ごとに分けると見出しつきの表が並ぶ() {
        var options = ExportOptions(includeAsk: false)
        options.layout = .block
        let text = ExportText.build(Self.request(metrics: [.steps, .heartRate], options: options))
        #expect(text.contains("## 歩数（歩） ／合計"))
        #expect(text.contains("## 心拍数（bpm） ／平均/最小/最大"))
        #expect(!text.contains("## 日ごとの記録"))
    }

    // MARK: - 大きさ

    @Test func 大きさの判定は閾値で変わる() {
        #expect(SizeEstimate.of("短い").verdict == .comfortable)
        #expect(SizeEstimate(characters: 0, lines: 0, approximateTokens: 70_000).verdict == .heavy)
        #expect(SizeEstimate(characters: 0, lines: 0, approximateTokens: 500_000).verdict == .tooLarge)
    }

    @Test func 見積もりは日本語と英数字を分けて数える() {
        #expect(SizeEstimate.of("abcd").approximateTokens == 1)     // 3.6文字で1
        #expect(SizeEstimate.of("あいう").approximateTokens == 3)   // 1文字で1
    }
}
