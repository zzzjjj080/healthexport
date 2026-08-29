import Foundation

/// テキストを組み立てるのに必要なものを、まとめて渡す入れ物。
/// **HealthKitの読み出しはアプリ層の仕事。**ここには読み終えた値だけが来る。
public struct ExportRequest: Sendable {
    public var range: DateRange
    public var metrics: [Metric]
    public var daily: [YMD: [MetricID: MetricValue]]
    public var workouts: [WorkoutEvent]
    public var rawSeries: [MetricID: RawSeries]
    public var devices: [String]
    public var purpose: Purpose
    public var options: ExportOptions
    public var exportedAt: Date

    public init(range: DateRange,
                metrics: [Metric],
                daily: [YMD: [MetricID: MetricValue]] = [:],
                workouts: [WorkoutEvent] = [],
                rawSeries: [MetricID: RawSeries] = [:],
                devices: [String] = [],
                purpose: Purpose = .general,
                options: ExportOptions = ExportOptions(),
                exportedAt: Date = Date()) {
        self.range = range
        self.metrics = metrics
        self.daily = daily
        self.workouts = workouts
        self.rawSeries = rawSeries
        self.devices = devices
        self.purpose = purpose
        self.options = options
        self.exportedAt = exportedAt
    }
}

public enum ExportText {

    // MARK: - 入口

    public static func build(_ request: ExportRequest) -> String {
        let options = request.options
        let language = options.language
        var blocks: [String] = []

        if options.includeAsk {
            blocks.append(request.purpose.askText(language))
        }
        if options.header != .none {
            blocks.append(headerBlock(request))
        }

        // 「1件ずつ全部」にした項目は日ごとの表から外す。日付で並ばないため。
        let rawIDs = options.rawMetrics
        let summaryMetrics = request.metrics.filter { !rawIDs.contains($0.id) }
        let rawMetrics = request.metrics.filter { rawIDs.contains($0.id) && $0.supportsRawSamples }

        if options.shortColumnNames {
            let legend = legendBlock(summaryMetrics, language: language)
            if !legend.isEmpty { blocks.append(legend) }
        }

        let tableMetrics = summaryMetrics.filter { $0.aggregation != .workoutList }
        if !tableMetrics.isEmpty {
            switch options.layout {
            case .wide:  blocks.append(wideBlock(request, metrics: tableMetrics))
            case .block: blocks.append(perMetricBlocks(request, metrics: tableMetrics))
            }
        }
        if request.metrics.contains(where: { $0.aggregation == .workoutList }) {
            blocks.append(workoutBlock(request))
        }
        for metric in rawMetrics {
            guard let series = request.rawSeries[metric.id] else { continue }
            blocks.append(rawBlock(metric: metric, series: series, options: options))
        }
        return blocks.filter { !$0.isEmpty }.joined(separator: "\n\n") + "\n"
    }

    // MARK: - 先頭の説明

    static func headerBlock(_ request: ExportRequest) -> String {
        let language = request.options.language
        let range = request.range
        var lines: [String] = []
        if language == .ja {
            lines.append("# ヘルスケアの記録")
            lines.append("期間: \(range.from.iso) 〜 \(range.to.iso)（\(range.dayCount)日間）")
        } else {
            lines.append("# Health data export")
            lines.append("Period: \(range.from.iso) to \(range.to.iso) (\(range.dayCount) days)")
        }
        guard request.options.header == .full else { return lines.joined(separator: "\n") }

        let stamp = timestamp(request.exportedAt)
        let devices = (request.options.includeDeviceNames && !request.devices.isEmpty)
            ? request.devices.joined(separator: " / ")
            : (language == .ja ? "（記載しない）" : "(not listed)")
        if language == .ja {
            lines.append("書き出し: \(stamp) / ヘルスケア書き出し")
            lines.append("記録した端末: \(devices)")
            lines.append("項目数: \(request.metrics.count)")
            lines.append("")
            lines.append("この文書はiPhoneのヘルスケアから本人が書き出したもの。")
            lines.append("値は同じ項目に複数の端末が記録した重複を、ヘルスケアが除いたあとの数字。")
            lines.append("空欄・欠けている日は「記録が無い」ことを表す（値が0という意味ではない）。")
        } else {
            lines.append("Exported: \(stamp) / Health Export")
            lines.append("Recorded by: \(devices)")
            lines.append("Metrics: \(request.metrics.count)")
            lines.append("")
            lines.append("Exported by the owner from the Health app on iPhone.")
            lines.append("Values are what Health reports after removing duplicates recorded by more than one device.")
            lines.append("A blank or missing day means no record exists (it does not mean zero).")
        }
        return lines.joined(separator: "\n")
    }

    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - 列

    /// 1項目が何列になるか。睡眠と心拍は複数列に開く。
    static func columnKeys(_ metric: Metric) -> [String] {
        switch metric.aggregation {
        case .sleep:         return ["total", "deep", "rem", "core", "bed", "wake"]
        case .minMaxAverage: return ["avg", "min", "max"]
        default:             return [""]
        }
    }

    static func columnLabel(_ metric: Metric, key: String, options: ExportOptions) -> String {
        if options.shortColumnNames {
            return key.isEmpty ? metric.shortKey : "\(metric.shortKey)_\(key)"
        }
        let language = options.language
        let name = metric.name(language)
        if key.isEmpty {
            let unit = metric.unit(language)
            return unit.isEmpty ? name : "\(name)(\(unit))"
        }
        return "\(name)(\(keyLabel(key, language)))"
    }

    static func keyLabel(_ key: String, _ language: Language) -> String {
        guard language == .ja else { return key }
        switch key {
        case "total": return "合計"
        case "deep":  return "深い"
        case "rem":   return "レム"
        case "core":  return "コア"
        case "awake": return "覚醒"
        case "bed":   return "就寝"
        case "wake":  return "起床"
        case "avg":   return "平均"
        case "min":   return "最小"
        case "max":   return "最大"
        default:      return key
        }
    }

    /// 1項目ぶんのセル。値が無ければ列の数だけ空文字を返す。
    static func cells(_ metric: Metric, value: MetricValue?) -> [String] {
        let keys = columnKeys(metric)
        guard let value else { return Array(repeating: "", count: keys.count) }
        switch value {
        case .number(let v):
            return [number(v, decimals: metric.decimals)]
        case .stats(let average, let low, let high):
            return [number(average, decimals: metric.decimals),
                    number(low, decimals: metric.decimals),
                    number(high, decimals: metric.decimals)]
        case .sleep(let sleep):
            return [number(sleep.total, decimals: 1),
                    number(sleep.deep, decimals: 1),
                    number(sleep.rem, decimals: 1),
                    number(sleep.core, decimals: 1),
                    sleep.bedMinute.map(clockLabel) ?? "",
                    sleep.wakeMinute.map(clockLabel) ?? ""]
        case .text(let text):
            return [text]
        }
    }

    static func number(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(max(0, decimals))f", value)
    }

    // MARK: - 日ごとの表

    static func wideBlock(_ request: ExportRequest, metrics: [Metric]) -> String {
        let options = request.options
        var head = ["date"]
        for metric in metrics {
            for key in columnKeys(metric) {
                head.append(columnLabel(metric, key: key, options: options))
            }
        }
        var rows = [head]
        for day in request.range.days {
            let values = request.daily[day]
            var row = [day.iso]
            var hasAny = false
            for metric in metrics {
                let value = values?[metric.id]
                if value != nil { hasAny = true }
                row.append(contentsOf: cells(metric, value: value))
            }
            if !hasAny && options.skipEmptyDays { continue }
            rows.append(row)
        }
        let title = options.language == .ja ? "## 日ごとの記録" : "## Daily values"
        return title + "\n" + table(rows, separator: options.separator)
    }

    static func perMetricBlocks(_ request: ExportRequest, metrics: [Metric]) -> String {
        let options = request.options
        let language = options.language
        var blocks: [String] = []
        for metric in metrics {
            let keys = columnKeys(metric)
            var head = ["date"]
            if keys == [""] {
                head.append("value")
            } else {
                head.append(contentsOf: keys)
            }
            var rows = [head]
            for day in request.range.days {
                let value = request.daily[day]?[metric.id]
                if value == nil && options.skipEmptyDays { continue }
                rows.append([day.iso] + cells(metric, value: value))
            }
            let unit = metric.unit(language)
            let heading = "## \(metric.name(language))"
                + (unit.isEmpty ? "" : (language == .ja ? "（\(unit)）" : " (\(unit))"))
                + (language == .ja ? " ／\(metric.aggregation.label(language))"
                                   : " / \(metric.aggregation.label(language))")
            blocks.append(heading + "\n" + table(rows, separator: options.separator))
        }
        return blocks.joined(separator: "\n\n")
    }

    // MARK: - ワークアウト

    static func workoutBlock(_ request: ExportRequest) -> String {
        let options = request.options
        let language = options.language
        let title = language == .ja ? "## ワークアウト" : "## Workouts"
        let inRange = request.workouts
            .filter { $0.day >= request.range.from && $0.day <= request.range.to }
            .sorted { ($0.day, $0.startMinute) < ($1.day, $1.startMinute) }
        guard !inRange.isEmpty else {
            let none = language == .ja ? "（この期間に記録なし）" : "(no records in this period)"
            return title + "\n" + none
        }
        let head = language == .ja
            ? ["date", "開始", "種目", "分", "kcal", "平均心拍"]
            : ["date", "start", "kind", "minutes", "kcal", "hr_avg"]
        var rows = [head]
        for workout in inRange {
            rows.append([workout.day.iso,
                         clockLabel(workout.startMinute),
                         workout.kind(language),
                         "\(workout.minutes)",
                         workout.kilocalories.map { number($0, decimals: 0) } ?? "",
                         workout.averageHeartRate.map { number($0, decimals: 0) } ?? ""])
        }
        return "\(title)（\(inRange.count)）\n" + table(rows, separator: options.separator)
    }

    // MARK: - 1件ずつ全部

    static func rawBlock(metric: Metric, series: RawSeries, options: ExportOptions) -> String {
        let language = options.language
        var rows: [[String]] = []
        switch series {
        case .numbers(let samples):
            rows.append(language == .ja ? ["日時", "値"] : ["datetime", "value"])
            for sample in samples {
                rows.append(["\(sample.day.iso) \(clockLabel(sample.minute))",
                             number(sample.value, decimals: metric.decimals)])
            }
        case .sleepSegments(let segments):
            rows.append(language == .ja ? ["開始", "終了", "段階"] : ["start", "end", "stage"])
            for segment in segments {
                rows.append(["\(segment.day.iso) \(clockLabel(segment.startMinute))",
                             clockLabel(segment.endMinute),
                             segment.stage(language)])
            }
        }
        let unit = metric.unit(language)
        let heading: String
        if language == .ja {
            heading = "## \(metric.name(language))" + (unit.isEmpty ? "" : "（\(unit)）")
                + " 詳細（全 \(series.count) 件）"
        } else {
            heading = "## \(metric.name(language))" + (unit.isEmpty ? "" : " (\(unit))")
                + " detail (\(series.count) samples)"
        }
        return heading + "\n" + table(rows, separator: options.separator)
    }

    // MARK: - 表の組み立て

    static func table(_ rows: [[String]], separator: Separator) -> String {
        switch separator {
        case .tab:
            return rows.map { $0.joined(separator: "\t") }.joined(separator: "\n")
        case .comma:
            // 値にカンマが混ざると列がずれる。混ざったものだけ引用符で囲む。
            return rows.map { row in
                row.map { cell in
                    (cell.contains(",") || cell.contains("\""))
                        ? "\"" + cell.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                        : cell
                }.joined(separator: ",")
            }.joined(separator: "\n")
        case .aligned:
            var widths: [Int] = []
            for row in rows {
                for (index, cell) in row.enumerated() {
                    let width = displayWidth(cell)
                    if index < widths.count { widths[index] = max(widths[index], width) }
                    else { widths.append(width) }
                }
            }
            return rows.map { row in
                row.enumerated().map { index, cell in
                    cell + String(repeating: " ", count: max(0, widths[index] - displayWidth(cell)) + 2)
                }.joined()
                .trimmingCharacters(in: CharacterSet(charactersIn: " "))
            }.joined(separator: "\n")
        }
    }

    /// 等幅で並べたときの見た目の幅。日本語は2、英数字は1で数える。
    static func displayWidth(_ text: String) -> Int {
        text.unicodeScalars.reduce(0) { $0 + ($1.value > 0x7F ? 2 : 1) }
    }

    // MARK: - 凡例

    static func legendBlock(_ metrics: [Metric], language: Language) -> String {
        let listed = metrics.filter { $0.aggregation != .workoutList }
        guard !listed.isEmpty else { return "" }
        var lines = [language == .ja ? "## 列の意味" : "## Column meanings"]
        for metric in listed {
            let keys = columnKeys(metric)
            let names = keys == [""] ? [metric.shortKey] : keys.map { "\(metric.shortKey)_\($0)" }
            let unit = metric.unit(language)
            lines.append("\(names.joined(separator: ", ")) = \(metric.name(language))"
                         + (unit.isEmpty ? "" : " (\(unit))"))
        }
        return lines.joined(separator: "\n")
    }
}
