import Foundation
import Observation
import SwiftUI
import HealthExportCore

/// 画面が見る状態のすべて。Viewはこれを見るだけにする。
@MainActor
@Observable
final class ExportModel {

    enum Phase: Equatable {
        case idle
        case scanning
        case reading(String)
        case done
    }

    var settings: AppSettings {
        didSet { save() }
    }
    private(set) var availability: [MetricID: MetricAvailability] = [:]
    private(set) var phase: Phase = .idle
    private(set) var exportedText: String?
    private(set) var estimate: SizeEstimate?
    private(set) var lastExportedAt: Date?
    var errorMessage: String?

    let reader = HealthReader()
    private let defaults: UserDefaults
    private let settingsKey = "settings.v1"
    private let introKey = "hasSeenIntro.v1"
    private var hasScanned = false

    /// 初回だけ説明を出す。2回目からは本題だけ見せる。
    var needsIntro: Bool { !defaults.bool(forKey: introKey) }
    func markIntroSeen() { defaults.set(true, forKey: introKey) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: settingsKey),
           let restored = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = restored
        } else {
            settings = AppSettings()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    // MARK: - 入口

    var range: DateRange { settings.effectiveRange() }

    var availableIDs: Set<MetricID> {
        Set(availability.filter(\.value.hasData).map(\.key))
    }

    var selectedMetrics: [Metric] {
        settings.effectiveMetrics(available: availableIDs)
    }

    /// 何も見つからなかったとき。
    /// **「データが無い」と断定してはいけない。**読み取りを拒否されていても同じ見え方になる。
    var foundNothing: Bool { hasScanned && availableIDs.isEmpty }

    var isBusy: Bool {
        switch phase {
        case .idle, .done: return false
        case .scanning, .reading: return true
        }
    }

    /// 起動時と、前面に戻ってきたときに呼ぶ。
    func refresh() async {
        guard !isBusy else { return }   // .task と .onChange が同時に走ることがある
        #if DEBUG
        if DemoData.isEnabled {
            await rescan()
            return
        }
        #endif
        if !hasScanned {
            guard await reader.requestAuthorization() else {
                errorMessage = reader.lastError
                return
            }
        }
        await rescan()
    }

    func rescan() async {
        phase = .scanning
        #if DEBUG
        if DemoData.isEnabled {
            availability = DemoData.availability(range: range)
            hasScanned = true
            phase = .idle
            return
        }
        #endif
        availability = await reader.scan(range: range)
        hasScanned = true
        if let error = reader.lastError { errorMessage = error }
        phase = .idle
    }

    /// 目的を選び直す。期間も項目も、目的にまかせる状態に戻す。
    func choose(_ purpose: Purpose) {
        settings.purpose = purpose
        settings.customDays = nil
        settings.customRange = nil
        settings.customMetrics = nil
        settings.options.rawMetrics = []
        exportedText = nil
        estimate = nil
    }

    // MARK: - 書き出し

    func export() async {
        guard !isBusy else { return }
        let metrics = selectedMetrics
        guard !metrics.isEmpty else {
            errorMessage = "書き出せる項目がありません。ヘルスケアの許可と、選んでいる期間を確かめてください。"
            return
        }
        phase = .reading("記録を読んでいます")
        var daily: DailyReadResult
        var rawSeries: [MetricID: RawSeries] = [:]
        #if DEBUG
        if DemoData.isEnabled {
            daily = DemoData.read(range: range, metrics: metrics)
            for id in settings.options.rawMetrics {
                let metric = MetricCatalog.metric(id)
                guard metric.supportsRawSamples, metrics.contains(where: { $0.id == id }) else { continue }
                rawSeries[id] = DemoData.rawSeries(metric: metric, range: range)
            }
        } else {
            daily = await readFromHealthKit(metrics: metrics, rawSeries: &rawSeries)
        }
        #else
        daily = await readFromHealthKit(metrics: metrics, rawSeries: &rawSeries)
        #endif
        if let error = reader.lastError { errorMessage = error }

        let request = ExportRequest(range: range,
                                    metrics: metrics,
                                    daily: daily.daily,
                                    workouts: daily.workouts,
                                    rawSeries: rawSeries,
                                    devices: daily.deviceNames,
                                    purpose: settings.purpose,
                                    options: settings.options,
                                    exportedAt: Date())
        let text = ExportText.build(request)
        exportedText = text
        estimate = SizeEstimate.of(text)
        lastExportedAt = Date()
        phase = .done
    }

    private func readFromHealthKit(metrics: [Metric],
                                   rawSeries: inout [MetricID: RawSeries]) async -> DailyReadResult {
        let daily = await reader.readDaily(range: range, metrics: metrics)
        for id in settings.options.rawMetrics {
            let metric = MetricCatalog.metric(id)
            guard metric.supportsRawSamples, metrics.contains(where: { $0.id == id }) else { continue }
            phase = .reading("\(metric.jaName)を1件ずつ読んでいます")
            if let series = await reader.readRaw(metric: metric, range: range) {
                rawSeries[id] = series
            }
        }
        return daily
    }

    /// 画面に出すぶんだけを切り出したもの。
    ///
    /// 「1件ずつ全部」を選ぶと10万行を超えることがあり、そのまま描くと固まる。
    /// 見せるのは頭だけでよい。**渡すのは常に全文**（コピーも共有もそちら）。
    var previewText: String {
        guard let text = exportedText else { return "" }
        let limit = 600
        var lines: [Substring] = []
        var total = 0
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            total += 1
            if lines.count < limit { lines.append(line) }
        }
        guard total > limit else { return text }
        let omitted = total - limit
        return lines.joined(separator: "\n")
            + "\n\n…… ここから先の \(omitted.formatted()) 行は画面に出していません。"
            + "\nコピーと共有には全部入っています。"
    }

    /// 共有シートに渡すファイル。名前で中身が分かるようにしておく。
    func writeTemporaryFile() -> URL? {
        guard let text = exportedText else { return nil }
        let name = "health_\(range.from.iso)_\(range.to.iso).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            errorMessage = "ファイルを作れませんでした: \(error.localizedDescription)"
            return nil
        }
    }
}
