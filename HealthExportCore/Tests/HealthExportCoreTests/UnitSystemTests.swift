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

    @Test func 端末の設定から単位系が決まる() {
        #expect(UnitSystem.forLocale(Locale(identifier: "en_US")) == .imperial)
        #expect(UnitSystem.forLocale(Locale(identifier: "ja_JP")) == .metric)
        #expect(UnitSystem.forLocale(Locale(identifier: "en_GB")) == .metric)   // 英国はメートル法
    }

    @Test func 端末の言語から表示する言語が決まる() {
        #expect(Language.forLocale(Locale(identifier: "ja_JP")) == .ja)
        #expect(Language.forLocale(Locale(identifier: "en_US")) == .en)
        #expect(Language.forLocale(Locale(identifier: "fr_FR")) == .fr)
        #expect(Language.forLocale(Locale(identifier: "de_DE")) == .de)
        #expect(Language.forLocale(Locale(identifier: "ko_KR")) == .ko)
        #expect(Language.forLocale(Locale(identifier: "ru_RU")) == .ru)
        #expect(Language.forLocale(Locale(identifier: "ar_SA")) == .ar)
        #expect(Language.forLocale(Locale(identifier: "es_MX")) == .es)
        #expect(Language.forLocale(Locale(identifier: "it_IT")) == .it)
    }

    /// 中国語とポルトガル語は、言語コードだけでは決まらない（引き継ぎ書 4-178）。
    @Test func 中国語とポルトガル語は地域まで見て決まる() {
        #expect(Language.forLocale(Locale(identifier: "zh_CN")) == .zhHans)
        #expect(Language.forLocale(Locale(identifier: "zh_SG")) == .zhHans)
        #expect(Language.forLocale(Locale(identifier: "zh_TW")) == .zhHant)   // 台湾は繁体字
        #expect(Language.forLocale(Locale(identifier: "zh_HK")) == .zhHant)   // 香港も繁体字
        #expect(Language.forLocale(Locale(identifier: "pt_BR")) == .ptBR)
        #expect(Language.forLocale(Locale(identifier: "pt_PT")) == .en)       // 欧州ポルトガル語は訳が無い
    }

    /// 訳を持たない言語は英語に落ちる。空白の画面を出さないための保険。
    @Test func 訳が無い言語は英語になる() {
        #expect(Language.forLocale(Locale(identifier: "th_TH")) == .en)
        #expect(Language.forLocale(Locale(identifier: "vi_VN")) == .en)
        #expect(Language.forLocale(Locale(identifier: "sv_SE")) == .en)
    }

    /// 12言語すべてで、画面と書き出しに出る言葉が空にならない。
    @Test func すべての言語で訳が空にならない() {
        for language in Language.allCases {
            for purpose in Purpose.allCases {
                #expect(!purpose.title(language).isEmpty, "\(language) の \(purpose) の見出しが空")
                #expect(!purpose.detail(language).isEmpty, "\(language) の \(purpose) の説明が空")
                #expect(purpose.askLines(language).count >= 2, "\(language) の \(purpose) の依頼文が短すぎる")
            }
            for metric in MetricCatalog.all {
                #expect(!metric.name(language).isEmpty, "\(language) の \(metric.id) の項目名が空")
            }
            for category in MetricCategory.allCases {
                #expect(!category.name(language).isEmpty, "\(language) の \(category) の分類名が空")
            }
            for days in PeriodChoice.steps {
                #expect(!PeriodChoice.label(days, language).isEmpty, "\(language) の \(days)日の呼び名が空")
            }
            #expect(!PeriodChoice.label(45, language).contains("%d"), "\(language) で日数が差し込まれていない")
        }
    }

    /// 日本語と英語以外でも、依頼文の末尾は必ず断りの一文で終わる。
    @Test func どの言語でも依頼文の最後は断りの一文() {
        for language in Language.allCases {
            let disclaimer = Tr.disclaimer[language] ?? ""
            #expect(!disclaimer.isEmpty, "\(language) の断りの一文が無い")
            for purpose in Purpose.allCases {
                #expect(purpose.askLines(language).last == disclaimer, "\(language) の \(purpose)")
                #expect(!purpose.askText(language).contains(Tr.disclaimerPlaceholder),
                        "\(language) の \(purpose) に目印が残っている")
            }
        }
    }
}
