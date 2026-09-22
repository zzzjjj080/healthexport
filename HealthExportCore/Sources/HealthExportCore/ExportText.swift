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
            let legend = legendBlock(summaryMetrics, language: language, system: options.unitSystem)
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
        // 枠の文言は Translations.json の export にある（12言語）。
        // 日英だけ分岐していた頃は、ほかの言語で書き出すと見出しと断り書きが英語のまま残った。
        lines.append(Tr.frame("title", language))
        lines.append(Tr.frame("period", language, ["from": range.from.iso, "to": range.to.iso,
                                                   "days": String(range.dayCount)]))
        guard request.options.header == .full else { return lines.joined(separator: "\n") }

        let stamp = timestamp(request.exportedAt)
        let devices = (request.options.includeDeviceNames && !request.devices.isEmpty)
            ? request.devices.joined(separator: " / ")
            : Tr.frame("notListed", language)
        lines.append(Tr.frame("exported", language, ["stamp": stamp]))
        lines.append(Tr.frame("recordedBy", language, ["devices": devices]))
        lines.append(Tr.frame("metricCount", language, ["count": String(request.metrics.count)]))
        lines.append("")
        lines.append(Tr.frame("note1", language))
        lines.append(Tr.frame("note2", language))
        lines.append(Tr.frame("note3", language))
        if request.options.grouping != .day {
            lines.append(Tr.frame("groupedNote", language))
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
            let short = metric.shortKey(options.unitSystem)
            return key.isEmpty ? short : "\(short)_\(key)"
        }
        let language = options.language
        let name = metric.name(language)
        if key.isEmpty {
            let unit = metric.unit(language, options.unitSystem)
            return unit.isEmpty ? name : "\(name)(\(unit))"
        }
        return "\(name)(\(keyLabel(key, language)))"
    }

    static func keyLabel(_ key: String, _ language: Language) -> String {
        // 表に無いキー（項目ごとの独自の列名）はそのまま出す。
        Tr.get(Tr.keyLabel, key, language)
    }

    /// 1項目ぶんのセル。値が無ければ列の数だけ空文字を返す。
    static func cells(_ metric: Metric, value: MetricValue?, language: Language = .ja) -> [String] {
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
        case .localized(let key, let table):
            switch table {
            case .mood: return [Tr.get(Tr.mood, key, language)]
            case .flow: return [Tr.get(Tr.flow, key, language)]
            }
        case .dayCount(let days):
            return [Tr.frame("dayCount", language, ["n": String(days)])]
        }
    }

    static func number(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(max(0, decimals))f", value)
    }

    /// 3桁ごとにカンマを入れる。`formatted()` は端末の言語で結果が変わるので使わない。
    static func grouped(_ value: Int) -> String {
        let digits = String(abs(value))
        var out = ""
        for (index, character) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 { out.append(",") }
            out.append(character)
        }
        return (value < 0 ? "-" : "") + out
    }

    // MARK: - 日ごとの表

    static func wideBlock(_ request: ExportRequest, metrics: [Metric]) -> String {
        let options = request.options
        let grouped = options.grouping != .day
        var head = [periodHead(options.grouping)] + (grouped ? ["days"] : [])
        for metric in metrics {
            for key in columnKeys(metric) {
                head.append(columnLabel(metric, key: key, options: options))
            }
        }
        var rows = [head]
        for period in Periods.rows(request) {
            let values = period.values
            var row = [period.label] + (grouped ? [String(period.days)] : [])
            var hasAny = false
            for metric in metrics {
                let value = values[metric.id]
                if value != nil { hasAny = true }
                row.append(contentsOf: cells(metric, value: value, language: options.language))
            }
            if !hasAny && options.skipEmptyDays { continue }
            rows.append(row)
        }
        let title = Tr.frame(tableTitleKey(options.grouping), options.language)
        return title + "\n" + table(rows, separator: options.separator)
    }

    /// 行の先頭の列名。日付と同じく英字の略号にしておく（列名は機械が読むもの）
    static func periodHead(_ grouping: Grouping) -> String {
        switch grouping {
        case .day: return "date"
        case .week: return "week"
        case .month: return "month"
        }
    }

    static func tableTitleKey(_ grouping: Grouping) -> String {
        switch grouping {
        case .day: return "daily"
        case .week: return "weekly"
        case .month: return "monthly"
        }
    }

    static func perMetricBlocks(_ request: ExportRequest, metrics: [Metric]) -> String {
        let options = request.options
        let language = options.language
        var blocks: [String] = []
        for metric in metrics {
            let keys = columnKeys(metric)
            let grouped = options.grouping != .day
            var head = [periodHead(options.grouping)] + (grouped ? ["days"] : [])
            if keys == [""] {
                head.append("value")
            } else {
                head.append(contentsOf: keys)
            }
            var rows = [head]
            for period in Periods.rows(request) {
                let value = period.values[metric.id]
                if value == nil && options.skipEmptyDays { continue }
                rows.append([period.label] + (grouped ? [String(period.days)] : [])
                            + cells(metric, value: value, language: language))
            }
            let unit = metric.unit(language, options.unitSystem)
            let heading = "## \(metric.name(language))"
                + (unit.isEmpty ? "" : Tr.frame("unitWrap", language, ["unit": unit]))
                + Tr.frame("aggSep", language, ["agg": metric.aggregation.label(language)])
            blocks.append(heading + "\n" + table(rows, separator: options.separator))
        }
        return blocks.joined(separator: "\n\n")
    }

    // MARK: - ワークアウト

    static func workoutBlock(_ request: ExportRequest) -> String {
        let options = request.options
        let language = options.language
        let title = Tr.frame("workouts", language)
        let inRange = request.workouts
            .filter { $0.day >= request.range.from && $0.day <= request.range.to }
            .sorted { ($0.day, $0.startMinute) < ($1.day, $1.startMinute) }
        guard !inRange.isEmpty else {
            let none = Tr.frame("noRecords", language)
            return title + "\n" + none
        }
        let head = ["date", Tr.frame("wStart", language), Tr.frame("wKind", language),
                    Tr.frame("wMinutes", language), "kcal", Tr.frame("wHr", language)]
        var rows = [head]
        for workout in inRange {
            rows.append([workout.day.iso,
                         clockLabel(workout.startMinute),
                         workout.kind(language),
                         "\(workout.minutes)",
                         workout.kilocalories.map { number($0, decimals: 0) } ?? "",
                         workout.averageHeartRate.map { number($0, decimals: 0) } ?? ""])
        }
        return title + Tr.frame("countWrap", language, ["n": String(inRange.count)]) + "\n"
            + table(rows, separator: options.separator)
    }

    // MARK: - 1件ずつ全部

    static func rawBlock(metric: Metric, series: RawSeries, options: ExportOptions) -> String {
        let language = options.language
        var rows: [[String]] = []
        switch series {
        case .numbers(let samples, _):
            rows.append([Tr.frame("rawDatetime", language), Tr.frame("rawValue", language)])
            for sample in samples {
                rows.append(["\(sample.day.iso) \(clockLabel(sample.minute))",
                             number(sample.value, decimals: metric.decimals)])
            }
        case .sleepSegments(let segments, _):
            rows.append([Tr.frame("rawStart", language), Tr.frame("rawEnd", language), Tr.frame("rawStage", language)])
            for segment in segments {
                rows.append(["\(segment.day.iso) \(clockLabel(segment.startMinute))",
                             clockLabel(segment.endMinute),
                             segment.stage(language)])
            }
        }
        let unit = metric.unit(language, options.unitSystem)
        var heading = "## \(metric.name(language))"
            + (unit.isEmpty ? "" : Tr.frame("unitWrap", language, ["unit": unit]))
            + Tr.frame("rawDetail", language, ["n": grouped(series.total)])
        // 黙って減らすと、AIが「この期間はこれだけしか記録が無い」と誤解する
        if series.isTruncated {
            heading += Tr.frame("truncated", language, ["n": grouped(series.count)])
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

    static func legendBlock(_ metrics: [Metric], language: Language, system: UnitSystem = .metric) -> String {
        let listed = metrics.filter { $0.aggregation != .workoutList }
        guard !listed.isEmpty else { return "" }
        var lines = [Tr.frame("columns", language)]
        for metric in listed {
            let keys = columnKeys(metric)
            let short = metric.shortKey(system)
            let names = keys == [""] ? [short] : keys.map { "\(short)_\($0)" }
            let unit = metric.unit(language, system)
            lines.append("\(names.joined(separator: ", ")) = \(metric.name(language))"
                         + (unit.isEmpty ? "" : " (\(unit))"))
        }
        return lines.joined(separator: "\n")
    }
}
