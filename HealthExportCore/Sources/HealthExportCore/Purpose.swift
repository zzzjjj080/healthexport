import Foundation

/// 何のためにAIへ渡すか。
///
/// これを選ぶだけで、期間・項目・依頼文がまとめて決まる。
/// 「日ごとにまとめるか、1件ずつ全部か」を素人が判断できない以上、
/// **既定でうまくいく組み合わせを用意しておくのがアプリの仕事。**
public enum Purpose: String, CaseIterable, Codable, Sendable {
    case general, sleep, training, condition, everything

    public var days: Int {
        switch self {
        case .general:    return 90
        case .sleep:      return 60
        case .training:   return 90
        case .condition:  return 30
        case .everything: return 90
        }
    }

    /// nil は「記録がある項目すべて」。
    public var metricIDs: [MetricID]? {
        switch self {
        case .general:
            return [.steps, .distance, .activeEnergy, .exerciseTime, .sleep,
                    .heartRate, .restingHeartRate, .hrv, .oxygenSaturation, .respiratoryRate,
                    .workouts, .bodyMass]
        case .sleep:
            return [.sleep, .heartRate, .restingHeartRate, .hrv, .respiratoryRate,
                    .oxygenSaturation, .wristTemperature, .steps, .activeEnergy, .exerciseTime]
        case .training:
            return [.workouts, .activeEnergy, .exerciseTime, .steps, .distance, .flights,
                    .heartRate, .restingHeartRate, .hrv, .vo2Max, .sleep]
        case .condition:
            return [.restingHeartRate, .hrv, .oxygenSaturation, .respiratoryRate, .wristTemperature,
                    .sleep, .steps, .activeEnergy, .stateOfMind]
        case .everything:
            return nil
        }
    }

    public func title(_ language: Language) -> String {
        switch (self, language) {
        case (.general, .ja):     return "ふだんの管理"
        case (.general, .en):     return "General check-in"
        case (.sleep, .ja):       return "睡眠のことを相談したい"
        case (.sleep, .en):       return "Ask about my sleep"
        case (.training, .ja):    return "運動のことを相談したい"
        case (.training, .en):    return "Ask about my training"
        case (.condition, .ja):   return "体調の変化を見てほしい"
        case (.condition, .en):   return "Check for changes in my condition"
        case (.everything, .ja):  return "全部渡す"
        case (.everything, .en):  return "Export everything"
        }
    }

    public func detail(_ language: Language) -> String {
        switch (self, language) {
        case (.general, .ja):     return "全体の傾向を見てもらう。迷ったらこれ。"
        case (.general, .en):     return "Overall trends. Start here if unsure."
        case (.sleep, .ja):       return "睡眠と、それに影響する項目にしぼる。"
        case (.sleep, .en):       return "Sleep and what affects it."
        case (.training, .ja):    return "運動量と、疲れの回復ぐあいを見てもらう。"
        case (.training, .en):    return "Training load and recovery."
        case (.condition, .ja):   return "ふだんと違う時期を見つけてもらう。直近1ヶ月。"
        case (.condition, .en):   return "Find periods that differ from baseline. Last month."
        case (.everything, .ja):  return "記録がある項目をすべて。長くなる。"
        case (.everything, .en):  return "Every metric with data. This gets long."
        }
    }

    /// AIへの依頼文。**末尾の一文は外さない。**
    /// 医療的な診断を求める文書ではないことを、渡した先にも自分にも明示しておく。
    public func askLines(_ language: Language) -> [String] {
        let disclaimerJa = "これは医療的な診断のためのものではありません。気になる症状があるときは受診します。"
        let disclaimerEn = "This is not for medical diagnosis. I will see a doctor if I have symptoms of concern."
        switch (self, language) {
        case (.general, .ja):
            return ["以下は私のiPhoneのヘルスケアに記録されている、この期間のデータです。",
                    "次のことを教えてください。",
                    "1. この期間の全体的な傾向（良くなっている点・悪くなっている点）",
                    "2. ほかの日と比べて明らかにずれている日と、その日に何があったと考えられるか",
                    "3. 数字から見て、生活のなかで続けるとよさそうなこと",
                    disclaimerJa]
        case (.general, .en):
            return ["Below is my health data exported from the Health app on my iPhone for this period.",
                    "Please tell me:",
                    "1. The overall trends in this period (what improved, what got worse)",
                    "2. Days that clearly stand out from the rest, and what might explain them",
                    "3. Habits worth keeping, based on what the numbers show",
                    disclaimerEn]
        case (.sleep, .ja):
            return ["以下は私の睡眠を中心とした記録です。",
                    "次のことを教えてください。",
                    "1. 睡眠時間と、その内訳（深い・レム・コア）の傾向",
                    "2. よく眠れた日とそうでない日で、日中の活動量や心拍にどんな違いがあるか",
                    "3. 眠りをよくするために、この数字から言えること",
                    disclaimerJa]
        case (.sleep, .en):
            return ["Below is my sleep-focused health data.",
                    "Please tell me:",
                    "1. Trends in total sleep and its stages (deep, REM, core)",
                    "2. How daytime activity and heart rate differ between good and bad nights",
                    "3. What these numbers suggest I could try to sleep better",
                    disclaimerEn]
        case (.training, .ja):
            return ["以下は私の運動と回復に関する記録です。",
                    "次のことを教えてください。",
                    "1. 運動量の推移と、負荷が高すぎた時期・少なすぎた時期",
                    "2. 安静時心拍・心拍変動・睡眠から見て、疲れが抜けているかどうか",
                    "3. これを踏まえた、次の1ヶ月の運動の組み立て方",
                    disclaimerJa]
        case (.training, .en):
            return ["Below is my training and recovery data.",
                    "Please tell me:",
                    "1. How my training load changed, and periods that were too hard or too light",
                    "2. Whether I am recovering, based on resting heart rate, HRV and sleep",
                    "3. How to structure the next month of training given all this",
                    disclaimerEn]
        case (.condition, .ja):
            return ["以下は私の直近の体調に関する記録です。",
                    "次のことを教えてください。",
                    "1. 安静時心拍・心拍変動・呼吸数・皮膚温から見て、ふだんと違っていた時期",
                    "2. その時期の睡眠や活動量に、いっしょに起きていた変化があるか",
                    "3. 記録のとり方として、足したほうがよい項目",
                    disclaimerJa]
        case (.condition, .en):
            return ["Below is my recent health data.",
                    "Please tell me:",
                    "1. Periods that differ from my baseline in resting heart rate, HRV, respiratory rate and skin temperature",
                    "2. Whether sleep or activity changed at the same time",
                    "3. What else I should start recording",
                    disclaimerEn]
        case (.everything, .ja):
            return ["以下は私のiPhoneのヘルスケアにある、この期間の記録すべてです。",
                    "気づいたことを自由に指摘してください。",
                    disclaimerJa]
        case (.everything, .en):
            return ["Below is everything recorded in the Health app on my iPhone for this period.",
                    "Please point out anything you notice.",
                    disclaimerEn]
        }
    }

    public func askText(_ language: Language) -> String {
        askLines(language).joined(separator: "\n")
    }
}
