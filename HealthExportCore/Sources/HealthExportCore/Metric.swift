import Foundation

/// 書き出せる項目。**表示名ではなくこのIDで記録する。**
/// 名前や単位は言語や版で変わるが、IDは変わらない。
public enum MetricID: String, CaseIterable, Codable, Sendable {
    case steps, distance, flights, activeEnergy, basalEnergy, exerciseTime, standTime, workouts
    case heartRate, restingHeartRate, hrv, walkingHeartRate, vo2Max
    case oxygenSaturation, respiratoryRate, wristTemperature
    case sleep
    case bodyMass, bodyFat
    case walkingSpeed, stepLength, walkingAsymmetry
    case headphoneAudio, environmentalAudio
    case mindful, stateOfMind
}

public enum MetricCategory: String, CaseIterable, Codable, Sendable {
    case activity, heart, respiratory, sleep, body, mobility, hearing, mind

    public func name(_ language: Language) -> String {
        switch (self, language) {
        case (.activity, .ja):    return "アクティビティ"
        case (.activity, .en):    return "Activity"
        case (.heart, .ja):       return "心臓"
        case (.heart, .en):       return "Heart"
        case (.respiratory, .ja): return "呼吸・体温"
        case (.respiratory, .en): return "Respiratory"
        case (.sleep, .ja):       return "睡眠"
        case (.sleep, .en):       return "Sleep"
        case (.body, .ja):        return "からだ"
        case (.body, .en):        return "Body"
        case (.mobility, .ja):    return "歩行の質"
        case (.mobility, .en):    return "Mobility"
        case (.hearing, .ja):     return "聴覚"
        case (.hearing, .en):     return "Hearing"
        case (.mind, .ja):        return "こころ"
        case (.mind, .en):        return "Mind"
        }
    }
}

/// その日の1つの数字に、どうやってまとめるか。
public enum Aggregation: String, Codable, Sendable {
    case sum            // 歩数・距離・カロリー・時間
    case average        // 心拍変動・血中酸素・呼吸数など
    case minMaxAverage  // 心拍数。平均だけだと動きが消える
    case latest         // 安静時心拍・体重・VO2maxなど、その日の代表値が1つ出るもの
    case sleep          // 合計と内訳
    case workoutList    // 日ごとの表には載らない。別の一覧にする
    case moodLatest     // 気分。数値ではなく言葉

    public func label(_ language: Language) -> String {
        switch (self, language) {
        case (.sum, .ja):           return "合計"
        case (.sum, .en):           return "sum"
        case (.average, .ja):       return "平均"
        case (.average, .en):       return "average"
        case (.minMaxAverage, .ja): return "平均/最小/最大"
        case (.minMaxAverage, .en): return "avg/min/max"
        case (.latest, .ja):        return "当日値"
        case (.latest, .en):        return "daily value"
        case (.sleep, .ja):         return "合計と内訳"
        case (.sleep, .en):         return "total and stages"
        case (.workoutList, .ja):   return "一覧"
        case (.workoutList, .en):   return "list"
        case (.moodLatest, .ja):    return "当日値"
        case (.moodLatest, .en):    return "daily value"
        }
    }
}

/// HealthKitのどの型から読むか。
/// **Coreは HealthKit を import しない**ので、識別子は文字列で持つ。
/// アプリ層がこれを `HKQuantityTypeIdentifier` などに変換する。
public enum HealthSource: Equatable, Sendable {
    case quantity(identifier: String, unit: String, scale: Double)
    case category(identifier: String)
    case workout
    case stateOfMind
}

public struct Metric: Identifiable, Equatable, Sendable {
    public let id: MetricID
    public let category: MetricCategory
    public let jaName: String
    public let enName: String
    public let jaUnit: String
    public let enUnit: String
    /// 列名を短くするときに使う英字。凡例に対応表を出す。
    public let shortKey: String
    public let source: HealthSource
    public let aggregation: Aggregation
    public let decimals: Int
    /// 「1件ずつ全部」を選んだときの重さを見積もるための、1日あたりの件数の目安。
    public let samplesPerDay: Int

    public func name(_ language: Language) -> String { language == .ja ? jaName : enName }
    public func unit(_ language: Language) -> String { language == .ja ? jaUnit : enUnit }

    /// 1件ずつの書き出しに意味があるか。ワークアウトと気分は元から件数が少ない。
    public var supportsRawSamples: Bool {
        switch aggregation {
        case .workoutList, .moodLatest, .latest: return false
        default: return samplesPerDay > 1
        }
    }
}

public enum MetricCatalog {
    /// 出力の列はこの順に並ぶ。並び順を変えると書き出したテキストの列順も変わる。
    public static let all: [Metric] = [
        Metric(id: .steps, category: .activity, jaName: "歩数", enName: "Steps",
               jaUnit: "歩", enUnit: "steps", shortKey: "steps",
               source: .quantity(identifier: "HKQuantityTypeIdentifierStepCount", unit: "count", scale: 1),
               aggregation: .sum, decimals: 0, samplesPerDay: 60),
        Metric(id: .distance, category: .activity, jaName: "歩行+走行距離", enName: "Walking+running distance",
               jaUnit: "km", enUnit: "km", shortKey: "dist_km",
               source: .quantity(identifier: "HKQuantityTypeIdentifierDistanceWalkingRunning", unit: "km", scale: 1),
               aggregation: .sum, decimals: 2, samplesPerDay: 60),
        Metric(id: .flights, category: .activity, jaName: "上った階数", enName: "Flights climbed",
               jaUnit: "階", enUnit: "floors", shortKey: "floors",
               source: .quantity(identifier: "HKQuantityTypeIdentifierFlightsClimbed", unit: "count", scale: 1),
               aggregation: .sum, decimals: 0, samplesPerDay: 20),
        Metric(id: .activeEnergy, category: .activity, jaName: "アクティブエネルギー", enName: "Active energy",
               jaUnit: "kcal", enUnit: "kcal", shortKey: "kcal_act",
               source: .quantity(identifier: "HKQuantityTypeIdentifierActiveEnergyBurned", unit: "kcal", scale: 1),
               aggregation: .sum, decimals: 0, samplesPerDay: 96),
        Metric(id: .basalEnergy, category: .activity, jaName: "安静時エネルギー", enName: "Resting energy",
               jaUnit: "kcal", enUnit: "kcal", shortKey: "kcal_bas",
               source: .quantity(identifier: "HKQuantityTypeIdentifierBasalEnergyBurned", unit: "kcal", scale: 1),
               aggregation: .sum, decimals: 0, samplesPerDay: 96),
        Metric(id: .exerciseTime, category: .activity, jaName: "エクササイズ時間", enName: "Exercise minutes",
               jaUnit: "分", enUnit: "min", shortKey: "exer_min",
               source: .quantity(identifier: "HKQuantityTypeIdentifierAppleExerciseTime", unit: "min", scale: 1),
               aggregation: .sum, decimals: 0, samplesPerDay: 96),
        Metric(id: .standTime, category: .activity, jaName: "スタンド時間", enName: "Stand minutes",
               jaUnit: "分", enUnit: "min", shortKey: "stand_min",
               source: .quantity(identifier: "HKQuantityTypeIdentifierAppleStandTime", unit: "min", scale: 1),
               aggregation: .sum, decimals: 0, samplesPerDay: 24),
        Metric(id: .workouts, category: .activity, jaName: "ワークアウト", enName: "Workouts",
               jaUnit: "", enUnit: "", shortKey: "workout",
               source: .workout, aggregation: .workoutList, decimals: 0, samplesPerDay: 1),

        Metric(id: .heartRate, category: .heart, jaName: "心拍数", enName: "Heart rate",
               jaUnit: "bpm", enUnit: "bpm", shortKey: "hr",
               source: .quantity(identifier: "HKQuantityTypeIdentifierHeartRate", unit: "count/min", scale: 1),
               aggregation: .minMaxAverage, decimals: 0, samplesPerDay: 1400),
        Metric(id: .restingHeartRate, category: .heart, jaName: "安静時心拍数", enName: "Resting heart rate",
               jaUnit: "bpm", enUnit: "bpm", shortKey: "rhr",
               source: .quantity(identifier: "HKQuantityTypeIdentifierRestingHeartRate", unit: "count/min", scale: 1),
               aggregation: .latest, decimals: 0, samplesPerDay: 1),
        Metric(id: .hrv, category: .heart, jaName: "心拍変動（SDNN）", enName: "Heart rate variability",
               jaUnit: "ms", enUnit: "ms", shortKey: "hrv_ms",
               source: .quantity(identifier: "HKQuantityTypeIdentifierHeartRateVariabilitySDNN", unit: "ms", scale: 1),
               aggregation: .average, decimals: 0, samplesPerDay: 6),
        Metric(id: .walkingHeartRate, category: .heart, jaName: "歩行時平均心拍数", enName: "Walking heart rate average",
               jaUnit: "bpm", enUnit: "bpm", shortKey: "whr",
               source: .quantity(identifier: "HKQuantityTypeIdentifierWalkingHeartRateAverage", unit: "count/min", scale: 1),
               aggregation: .latest, decimals: 0, samplesPerDay: 1),
        Metric(id: .vo2Max, category: .heart, jaName: "心肺機能（VO2max）", enName: "Cardio fitness (VO2max)",
               jaUnit: "mL/kg/min", enUnit: "mL/kg/min", shortKey: "vo2",
               source: .quantity(identifier: "HKQuantityTypeIdentifierVO2Max", unit: "ml/kg*min", scale: 1),
               aggregation: .latest, decimals: 1, samplesPerDay: 1),

        // 割合の単位は HealthKit では 0〜1 で返ってくる。100倍して%にする。
        Metric(id: .oxygenSaturation, category: .respiratory, jaName: "血中酸素", enName: "Blood oxygen",
               jaUnit: "%", enUnit: "%", shortKey: "spo2",
               source: .quantity(identifier: "HKQuantityTypeIdentifierOxygenSaturation", unit: "%", scale: 100),
               aggregation: .average, decimals: 0, samplesPerDay: 14),
        Metric(id: .respiratoryRate, category: .respiratory, jaName: "呼吸数", enName: "Respiratory rate",
               jaUnit: "回/分", enUnit: "breaths/min", shortKey: "resp",
               source: .quantity(identifier: "HKQuantityTypeIdentifierRespiratoryRate", unit: "count/min", scale: 1),
               aggregation: .average, decimals: 1, samplesPerDay: 9),
        Metric(id: .wristTemperature, category: .respiratory, jaName: "手首皮膚温の変化", enName: "Wrist temperature deviation",
               jaUnit: "℃", enUnit: "C", shortKey: "temp_dev",
               source: .quantity(identifier: "HKQuantityTypeIdentifierAppleSleepingWristTemperature", unit: "degC", scale: 1),
               aggregation: .latest, decimals: 2, samplesPerDay: 1),

        Metric(id: .sleep, category: .sleep, jaName: "睡眠", enName: "Sleep",
               jaUnit: "時間", enUnit: "h", shortKey: "sleep",
               source: .category(identifier: "HKCategoryTypeIdentifierSleepAnalysis"),
               aggregation: .sleep, decimals: 1, samplesPerDay: 40),

        Metric(id: .bodyMass, category: .body, jaName: "体重", enName: "Body mass",
               jaUnit: "kg", enUnit: "kg", shortKey: "kg",
               source: .quantity(identifier: "HKQuantityTypeIdentifierBodyMass", unit: "kg", scale: 1),
               aggregation: .latest, decimals: 1, samplesPerDay: 1),
        Metric(id: .bodyFat, category: .body, jaName: "体脂肪率", enName: "Body fat percentage",
               jaUnit: "%", enUnit: "%", shortKey: "fat_pct",
               source: .quantity(identifier: "HKQuantityTypeIdentifierBodyFatPercentage", unit: "%", scale: 100),
               aggregation: .latest, decimals: 1, samplesPerDay: 1),

        Metric(id: .walkingSpeed, category: .mobility, jaName: "歩行速度", enName: "Walking speed",
               jaUnit: "km/h", enUnit: "km/h", shortKey: "w_speed",
               source: .quantity(identifier: "HKQuantityTypeIdentifierWalkingSpeed", unit: "km/hr", scale: 1),
               aggregation: .average, decimals: 2, samplesPerDay: 8),
        Metric(id: .stepLength, category: .mobility, jaName: "歩幅", enName: "Walking step length",
               jaUnit: "cm", enUnit: "cm", shortKey: "w_len_cm",
               source: .quantity(identifier: "HKQuantityTypeIdentifierWalkingStepLength", unit: "cm", scale: 1),
               aggregation: .average, decimals: 0, samplesPerDay: 8),
        Metric(id: .walkingAsymmetry, category: .mobility, jaName: "歩行の非対称性", enName: "Walking asymmetry",
               jaUnit: "%", enUnit: "%", shortKey: "w_asym",
               source: .quantity(identifier: "HKQuantityTypeIdentifierWalkingAsymmetryPercentage", unit: "%", scale: 100),
               aggregation: .average, decimals: 1, samplesPerDay: 8),

        Metric(id: .headphoneAudio, category: .hearing, jaName: "ヘッドフォン音量", enName: "Headphone audio levels",
               jaUnit: "dB", enUnit: "dB", shortKey: "hp_db",
               source: .quantity(identifier: "HKQuantityTypeIdentifierHeadphoneAudioExposure", unit: "dBASPL", scale: 1),
               aggregation: .average, decimals: 0, samplesPerDay: 20),
        Metric(id: .environmentalAudio, category: .hearing, jaName: "環境音レベル", enName: "Environmental sound levels",
               jaUnit: "dB", enUnit: "dB", shortKey: "env_db",
               source: .quantity(identifier: "HKQuantityTypeIdentifierEnvironmentalAudioExposure", unit: "dBASPL", scale: 1),
               aggregation: .average, decimals: 0, samplesPerDay: 30),

        Metric(id: .mindful, category: .mind, jaName: "マインドフルネス", enName: "Mindful minutes",
               jaUnit: "分", enUnit: "min", shortKey: "mind_min",
               source: .category(identifier: "HKCategoryTypeIdentifierMindfulSession"),
               aggregation: .sum, decimals: 0, samplesPerDay: 2),
        Metric(id: .stateOfMind, category: .mind, jaName: "気分の記録", enName: "State of mind",
               jaUnit: "", enUnit: "", shortKey: "mood",
               source: .stateOfMind, aggregation: .moodLatest, decimals: 0, samplesPerDay: 2),
    ]

    public static func metric(_ id: MetricID) -> Metric {
        // カタログは全IDを網羅している。網羅していなければテストで落ちる。
        all.first { $0.id == id }!
    }

    public static func metrics(_ ids: [MetricID]) -> [Metric] {
        all.filter { ids.contains($0.id) }
    }
}
