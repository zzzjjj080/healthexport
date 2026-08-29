import Foundation

public enum Layout: String, Codable, Sendable, CaseIterable { case wide, block }
public enum Separator: String, Codable, Sendable, CaseIterable { case tab, comma, aligned }
public enum HeaderDetail: String, Codable, Sendable, CaseIterable { case full, minimal, none }

/// 書き出しの形。ふつうは触らずに済むよう、既定でうまくいく値を入れてある。
public struct ExportOptions: Equatable, Sendable, Codable {
    public var language: Language
    public var layout: Layout
    public var separator: Separator
    /// 列名を英字の略称にする。凡例が付くぶん、長い期間では全体が短くなる。
    public var shortColumnNames: Bool
    public var header: HeaderDetail
    public var includeAsk: Bool
    public var skipEmptyDays: Bool
    /// 「1件ずつ全部」を選んだ項目。既定は空＝すべて日ごとにまとめる。
    public var rawMetrics: Set<MetricID>
    /// 端末の名前を書き出しに含めるか。
    /// ヘルスケアの端末名は「〇〇のApple Watch」のように**本名が入っていることが多い。**
    /// 渡す相手によっては外したいので、切れるようにしてある。
    public var includeDeviceNames: Bool

    public init(language: Language = .ja,
                layout: Layout = .wide,
                separator: Separator = .tab,
                shortColumnNames: Bool = false,
                header: HeaderDetail = .full,
                includeAsk: Bool = true,
                skipEmptyDays: Bool = true,
                rawMetrics: Set<MetricID> = [],
                includeDeviceNames: Bool = true) {
        self.language = language
        self.layout = layout
        self.separator = separator
        self.shortColumnNames = shortColumnNames
        self.header = header
        self.includeAsk = includeAsk
        self.skipEmptyDays = skipEmptyDays
        self.rawMetrics = rawMetrics
        self.includeDeviceNames = includeDeviceNames
    }

    // 項目を1つ足しただけで、それまでの設定が丸ごと読めなくなるのを防ぐ。
    // `decode` は1つでも欠けると失敗するので、必ず decodeIfPresent と既定値で受ける。
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(Language.self, forKey: .language) ?? .ja
        layout = try c.decodeIfPresent(Layout.self, forKey: .layout) ?? .wide
        separator = try c.decodeIfPresent(Separator.self, forKey: .separator) ?? .tab
        shortColumnNames = try c.decodeIfPresent(Bool.self, forKey: .shortColumnNames) ?? false
        header = try c.decodeIfPresent(HeaderDetail.self, forKey: .header) ?? .full
        includeAsk = try c.decodeIfPresent(Bool.self, forKey: .includeAsk) ?? true
        skipEmptyDays = try c.decodeIfPresent(Bool.self, forKey: .skipEmptyDays) ?? true
        rawMetrics = try c.decodeIfPresent(Set<MetricID>.self, forKey: .rawMetrics) ?? []
        includeDeviceNames = try c.decodeIfPresent(Bool.self, forKey: .includeDeviceNames) ?? true
    }
}

/// アプリが覚えておく設定のすべて。
///
/// 期間と項目は「目的を選べば決まる」ので、**触ったときだけ** ここに残る。
/// nil は「目的にまかせる」。
public struct AppSettings: Equatable, Sendable, Codable {
    public var purpose: Purpose
    public var customDays: Int?
    public var customRange: DateRange?
    public var customMetrics: [MetricID]?
    public var options: ExportOptions

    public init(purpose: Purpose = .general,
                customDays: Int? = nil,
                customRange: DateRange? = nil,
                customMetrics: [MetricID]? = nil,
                options: ExportOptions = ExportOptions()) {
        self.purpose = purpose
        self.customDays = customDays
        self.customRange = customRange
        self.customMetrics = customMetrics
        self.options = options
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        purpose = try c.decodeIfPresent(Purpose.self, forKey: .purpose) ?? .general
        customDays = try c.decodeIfPresent(Int.self, forKey: .customDays)
        customRange = try c.decodeIfPresent(DateRange.self, forKey: .customRange)
        customMetrics = try c.decodeIfPresent([MetricID].self, forKey: .customMetrics)
        options = try c.decodeIfPresent(ExportOptions.self, forKey: .options) ?? ExportOptions()
    }

    /// 実際に書き出す期間。日付を直に指定していればそれを、無ければ目的の日数から作る。
    public func effectiveRange(today: YMD = .today()) -> DateRange {
        if let customRange { return customRange }
        return DateRange.recent(days: customDays ?? PeriodChoice.defaultDays, today: today)
    }

    /// 実際に書き出す項目。記録がある項目だけに絞ってから返す。
    ///
    /// - Parameter available: その期間に記録があった項目。
    ///   **ここに無いものは、選ばれていても外す。**
    ///   「選んだのに空の列が並ぶ」ほうが、AIにも人にも紛らわしい。
    public func effectiveMetrics(available: Set<MetricID>) -> [Metric] {
        let wanted: [MetricID]
        if let customMetrics {
            wanted = customMetrics
        } else if let ids = purpose.metricIDs {
            wanted = ids
        } else {
            wanted = MetricID.allCases
        }
        // 並び順はカタログの順。目的ごとに列の順が変わると読み比べにくい。
        return MetricCatalog.all.filter { wanted.contains($0.id) && available.contains($0.id) }
    }
}
