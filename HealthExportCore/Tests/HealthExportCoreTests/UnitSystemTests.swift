import Foundation
import Testing
@testable import HealthExportCore

/// 英語圏に渡すときの単位。HealthKit の中身はメートル法なので、
/// 取り出す単位と、書き出しの表記の両方を切り替える。
struct UnitSystemTests {

    @Test func 距離と体重はヤードポンドに切り替わる() {
        let distance = MetricCatalog.metric(.distance)
        #expect(distance.unit(.en, .metric) == "km")
        #expect(distance.unit(.en, .imperial) == "mi")
        #expect(distance.healthKitUnit(.imperial) == "mi")
        #expect(distance.shortKey(.imperial) == "dist_mi")

        let weight = MetricCatalog.metric(.bodyMass)
        #expect(weight.unit(.ja, .imperial) == "lb")
        #expect(weight.healthKitUnit(.imperial) == "lb")
    }

    @Test func 歩行速度と歩幅も切り替わる() {
        #expect(MetricCatalog.metric(.walkingSpeed).unit(.en, .imperial) == "mph")
        #expect(MetricCatalog.metric(.walkingSpeed).healthKitUnit(.imperial) == "mi/hr")
        #expect(MetricCatalog.metric(.stepLength).unit(.en, .imperial) == "in")
    }

    @Test func 単位が国で変わらない項目はそのまま() {
        for id in [MetricID.steps, .heartRate, .oxygenSaturation, .sleep] {
            let m = MetricCatalog.metric(id)
            #expect(m.unit(.en, .imperial) == m.unit(.en, .metric))
            #expect(m.shortKey(.imperial) == m.shortKey)
        }
        // 手首皮膚温の「変化」は差分なので、華氏の換算を掛けると壊れる。変換しない
        #expect(MetricCatalog.metric(.wristTemperature).imperial == nil)
    }

    @Test func 書き出しにも単位が反映される() {
        var options = ExportOptions(includeAsk: false)
        options.language = .en
        options.unitSystem = .imperial
        let request = ExportRequest(range: DateRange(from: YMD(2026, 6, 1), to: YMD(2026, 6, 1)),
                                    metrics: MetricCatalog.metrics([.distance, .bodyMass]),
                                    daily: [YMD(2026, 6, 1): [.distance: .number(3.6), .bodyMass: .number(146.4)]],
                                    options: options)
        let text = ExportText.build(request)
        #expect(text.contains("Walking+running distance(mi)"))
        #expect(text.contains("Body mass(lb)"))
        #expect(!text.contains("(km)"))

        options.shortColumnNames = true
        let short = ExportText.build(ExportRequest(range: request.range, metrics: request.metrics,
                                                   daily: request.daily, options: options))
        #expect(short.contains("dist_mi"))
        #expect(short.contains("dist_mi = Walking+running distance (mi)"))
    }

    /// 単位系の項目が無い古い設定でも、メートル法として読める（引き継ぎ書 4-21）。
    @Test func 古い設定は単位系がメートル法になる() throws {
        let old = #"{"language":"en"}"#.data(using: .utf8)!
        let options = try JSONDecoder().decode(ExportOptions.self, from: old)
        #expect(options.unitSystem == .metric)
    }

    @Test func 端末の設定から単位系と言語が決まる() {
        #expect(UnitSystem.forLocale(Locale(identifier: "en_US")) == .imperial)
        #expect(UnitSystem.forLocale(Locale(identifier: "ja_JP")) == .metric)
        #expect(UnitSystem.forLocale(Locale(identifier: "en_GB")) == .metric)   // 英国はメートル法
        #expect(Language.forLocale(Locale(identifier: "ja_JP")) == .ja)
        #expect(Language.forLocale(Locale(identifier: "en_US")) == .en)
        #expect(Language.forLocale(Locale(identifier: "fr_FR")) == .en)        // 日本語以外は英語
    }
}
