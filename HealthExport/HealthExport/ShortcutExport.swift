import AppIntents
import Foundation
import UIKit
import HealthExportCore

/// ショートカット（App Intents）から書き出す。
///
/// **画面を開かずに、アプリの裏で走る。** 「毎月1日に先月ぶんを書き出してコピー」のような
/// オートメーションや、アクションボタン・Siri から呼べるようにするためのもの。
/// 形式（言語・単位・表の1行・項目）は**アプリの設定をそのまま使う**。
/// ショートカット側で選べるのは、目的・期間・まとめ方だけにしてある。
struct ExportHealthDataIntent: AppIntent {
    static var title: LocalizedStringResource = "ヘルスケアを書き出す"
    static var description = IntentDescription(
        "ヘルスケアの記録を、AIに渡せるテキストにまとめます。形式はアプリの設定に従います。")
    /// 裏で走らせる。開いてしまうと、オートメーションに組み込めない
    static var openAppWhenRun = false

    @Parameter(title: "目的", default: .general)
    var purpose: PurposeChoice

    @Parameter(title: "期間", default: .threeMonths)
    var period: PeriodOption

    @Parameter(title: "表の1行", default: .day)
    var grouping: GroupingOption

    @Parameter(title: "コピーする", default: true)
    var copyToClipboard: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$purpose)を\(\.$period)ぶん書き出す") {
            \.$grouping
            \.$copyToClipboard
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let result = await ShortcutExport.run(purpose: purpose.core, days: period.days, grouping: grouping.core)
        switch result {
        case .failure(let message):
            // ショートカットの実行を止めて、理由をそのまま見せる
            throw ExportProblem.couldNotExport(message)
        case .success(let text, let summary):
            if copyToClipboard { UIPasteboard.general.string = text }
            return .result(value: text, dialog: IntentDialog(stringLiteral: summary))
        }
    }
}

/// ショートカットから呼ぶときの、名前の付いた呼び出し方。
struct HealthExportShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExportHealthDataIntent(),
            phrases: [
                "\(.applicationName)で書き出す",
                "\(.applicationName)でヘルスケアを書き出す",
                "Export my health data with \(.applicationName)",
                "Export health text with \(.applicationName)",
            ],
            shortTitle: "ヘルスケアを書き出す",
            systemImageName: "square.and.arrow.up")
    }
}

/// ショートカットに出す、失敗の理由。
enum ExportProblem: Error, CustomLocalizedStringResourceConvertible {
    case couldNotExport(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .couldNotExport(let message): return LocalizedStringResource(stringLiteral: message)
        }
    }
}

// MARK: - ショートカットで選べるもの

enum PurposeChoice: String, AppEnum {
    case general, sleep, training, condition, mind, everything

    var core: Purpose { Purpose(rawValue: rawValue) ?? .general }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "目的")
    static var caseDisplayRepresentations: [PurposeChoice: DisplayRepresentation] = [
        .general:    "ふだんの管理",
        .sleep:      "睡眠のこと",
        .training:   "運動のこと",
        .condition:  "体調の変化",
        .mind:       "こころの調子",
        .everything: "質問せずに渡す",
    ]
}

/// 期間は、アプリの「直近」と同じ段に揃える。加えて「先月」を置く
/// （毎月1日に先月ぶんを書き出す、がいちばん使う形だと考えた）。
enum PeriodOption: String, AppEnum {
    case twoWeeks, oneMonth, threeMonths, sixMonths, oneYear, lastMonth

    var days: PeriodSelection {
        switch self {
        case .twoWeeks:    return .recent(14)
        case .oneMonth:    return .recent(30)
        case .threeMonths: return .recent(90)
        case .sixMonths:   return .recent(180)
        case .oneYear:     return .recent(365)
        case .lastMonth:   return .lastCalendarMonth
        }
    }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "期間")
    static var caseDisplayRepresentations: [PeriodOption: DisplayRepresentation] = [
        .twoWeeks:    "2週間",
        .oneMonth:    "1ヶ月",
        .threeMonths: "3ヶ月",
        .sixMonths:   "6ヶ月",
        .oneYear:     "1年",
        .lastMonth:   "先月",
    ]
}

enum GroupingOption: String, AppEnum {
    case day, week, month

    var core: Grouping { Grouping(rawValue: rawValue) ?? .day }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "表の1行")
    static var caseDisplayRepresentations: [GroupingOption: DisplayRepresentation] = [
        .day:   "1日ごと",
        .week:  "週ごと",
        .month: "月ごと",
    ]
}

enum PeriodSelection {
    case recent(Int)
    case lastCalendarMonth

    /// 「先月」は暦の月。1日に走らせても、月の途中で走らせても、先月ぶん全体になる。
    func range(today: YMD = .today()) -> DateRange {
        switch self {
        case .recent(let days):
            return DateRange.recent(days: days, today: today)
        case .lastCalendarMonth:
            let year = today.month == 1 ? today.year - 1 : today.year
            let month = today.month == 1 ? 12 : today.month - 1
            let last = [31, (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28,
                        31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
            return DateRange(from: YMD(year, month, 1), to: YMD(year, month, last))
        }
    }
}

// MARK: - 実際に読んで組み立てるところ

/// 画面を通さずに書き出す。**設定はアプリと同じものを読む**（UserDefaults の settings.v1）。
enum ShortcutExport {

    enum Result {
        case success(text: String, summary: String)
        case failure(String)
    }

    @MainActor
    static func run(purpose: Purpose, days: PeriodSelection, grouping: Grouping,
                    defaults: UserDefaults = .standard) async -> Result {
        var settings = AppSettings()
        if let data = defaults.data(forKey: "settings.v1"),
           let restored = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = restored
        }
        settings.purpose = purpose
        settings.customMetrics = nil        // 目的にまかせる（画面で選んだ項目には引きずられない）
        settings.options.grouping = grouping
        let range = days.range()

        let reader = HealthReader()
        reader.unitSystem = settings.options.unitSystem
        let availability = await reader.scan(range: range, includeCycle: settings.includeCycle)
        let available = Set(availability.filter(\.value.hasData).map(\.key))
        let metrics = settings.effectiveMetrics(available: available)
        guard !metrics.isEmpty else {
            // 端末がロックされている間はヘルスケアを読めない。0件と区別が付かないので両方書く
            return .failure(String(localized: "書き出せる記録が見つかりませんでした。ヘルスケアの許可と期間を確かめてください。iPhoneがロックされている間は読み取れません。"))
        }
        let daily = await reader.readDaily(range: range, metrics: metrics)
        let text = ExportText.build(ExportRequest(
            range: range, metrics: metrics, daily: daily.daily, workouts: daily.workouts,
            devices: daily.deviceNames, purpose: settings.purpose,
            options: settings.options, exportedAt: Date()))
        let estimate = SizeEstimate.of(text)
        let summary = String(localized: "\(metrics.count)項目・\(estimate.characters)文字を書き出しました。")
        return .success(text: text, summary: summary)
    }
}
