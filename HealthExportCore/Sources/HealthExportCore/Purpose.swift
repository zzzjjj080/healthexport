import Foundation

/// 何のためにAIへ渡すか。
///
/// これを選ぶだけで、期間・項目・依頼文がまとめて決まる。
/// 「日ごとにまとめるか、1件ずつ全部か」を素人が判断できない以上、
/// **既定でうまくいく組み合わせを用意しておくのがアプリの仕事。**
public enum Purpose: String, CaseIterable, Codable, Sendable {
    case general, sleep, training, condition, mind, everything

    /// nil は「記録がある項目すべて」。
    public var metricIDs: [MetricID]? {
        switch self {
        // 既定は「記録がある項目を全部」。
        // 何が役に立つかは渡してみないと分からないし、日ごとにまとめてあれば
        // 全項目でも3ヶ月で2万字ほどにしかならない。選ぶ手間をかけさせない。
        case .general:
            return nil
        case .sleep:
            return [.sleep, .heartRate, .restingHeartRate, .hrv, .respiratoryRate,
                    .oxygenSaturation, .wristTemperature, .steps, .activeEnergy, .exerciseTime]
        case .training:
            return [.workouts, .activeEnergy, .exerciseTime, .steps, .distance, .flights,
                    .heartRate, .restingHeartRate, .hrv, .vo2Max, .sleep]
        case .condition:
            return [.restingHeartRate, .hrv, .oxygenSaturation, .respiratoryRate, .wristTemperature,
                    .sleep, .steps, .activeEnergy, .stateOfMind]
        case .mind:
            return [.stateOfMind, .mindful, .sleep, .hrv, .restingHeartRate,
                    .respiratoryRate, .steps, .activeEnergy, .exerciseTime]
        case .everything:
            return nil
        }
    }

    public func title(_ language: Language) -> String {
        Tr.get(Tr.purposeTitle, rawValue, language)
    }

    public func detail(_ language: Language) -> String {
        Tr.get(Tr.purposeDetail, rawValue, language)
    }

    /// AIへの依頼文。**末尾の一文は外さない。**
    /// 医療的な診断を求める文書ではないことを、渡した先にも自分にも明示しておく。
    ///
    /// 文そのものは Translations.json にある（12言語）。ここでは末尾に免責の一文を足すだけ。
    public func askLines(_ language: Language) -> [String] {
        let lines = Tr.askLines[rawValue]?[language]
            ?? Tr.askLines[rawValue]?[Language.fallback] ?? []
        let disclaimer = Tr.disclaimer[language] ?? Tr.disclaimer[Language.fallback]!
        return lines.map { $0 == Tr.disclaimerPlaceholder ? disclaimer : $0 }
    }

    public func askText(_ language: Language) -> String {
        askLines(language).joined(separator: "\n")
    }
}
