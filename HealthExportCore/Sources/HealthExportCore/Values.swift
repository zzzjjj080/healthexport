import Foundation

public enum Language: String, Codable, Sendable, CaseIterable {
    case ja, en
}

/// その日の1項目ぶんの値。
///
/// 「数値」「平均と最小最大」「睡眠」「言葉」を1つの型で表す。
/// `Double?` と `Bool` の組み合わせで持つと、あり得ない組み合わせが作れてしまう。
public enum MetricValue: Equatable, Sendable {
    case number(Double)
    case stats(average: Double, min: Double, max: Double)
    case sleep(SleepSummary)
    case text(String)
}

/// 1晩ぶんの睡眠。時間はすべて「時間」単位。
public struct SleepSummary: Equatable, Sendable {
    public let total: Double
    public let deep: Double
    public let rem: Double
    public let core: Double
    public let awake: Double
    /// 就寝・起床。午前0時からの分。前夜にまたがるので 0〜1439 に丸めて持つ。
    public let bedMinute: Int?
    public let wakeMinute: Int?

    public init(total: Double, deep: Double, rem: Double, core: Double, awake: Double,
                bedMinute: Int? = nil, wakeMinute: Int? = nil) {
        self.total = total
        self.deep = deep
        self.rem = rem
        self.core = core
        self.awake = awake
        self.bedMinute = bedMinute
        self.wakeMinute = wakeMinute
    }
}

/// 1件のワークアウト。
/// 種目名は HealthKit の列挙から引くので、**日英ともアプリ層が埋めて渡す。**
/// Core が種目番号を解釈すると、OSが種目を足したときに黙って間違える。
public struct WorkoutEvent: Equatable, Sendable {
    public let day: YMD
    public let startMinute: Int
    public let minutes: Int
    public let kilocalories: Double?
    public let averageHeartRate: Double?
    public let kindJa: String
    public let kindEn: String

    public init(day: YMD, startMinute: Int, minutes: Int, kilocalories: Double? = nil,
                averageHeartRate: Double? = nil, kindJa: String, kindEn: String) {
        self.day = day
        self.startMinute = startMinute
        self.minutes = minutes
        self.kilocalories = kilocalories
        self.averageHeartRate = averageHeartRate
        self.kindJa = kindJa
        self.kindEn = kindEn
    }

    public func kind(_ language: Language) -> String { language == .ja ? kindJa : kindEn }
}

/// 「1件ずつ全部」を選んだときの1サンプル。
public struct RawSample: Equatable, Sendable {
    public let day: YMD
    public let minute: Int      // 午前0時からの分
    public let value: Double

    public init(day: YMD, minute: Int, value: Double) {
        self.day = day
        self.minute = minute
        self.value = value
    }
}

/// 睡眠を1件ずつ出すときの1区間。
public struct SleepSegment: Equatable, Sendable {
    public let day: YMD
    public let startMinute: Int
    public let endMinute: Int
    public let stageJa: String
    public let stageEn: String

    public init(day: YMD, startMinute: Int, endMinute: Int, stageJa: String, stageEn: String) {
        self.day = day
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.stageJa = stageJa
        self.stageEn = stageEn
    }

    public func stage(_ language: Language) -> String { language == .ja ? stageJa : stageEn }
}

public enum RawSeries: Equatable, Sendable {
    case numbers([RawSample])
    case sleepSegments([SleepSegment])

    public var count: Int {
        switch self {
        case .numbers(let s): return s.count
        case .sleepSegments(let s): return s.count
        }
    }
}

/// 午前0時からの分を "HH:mm" にする。24時間を超えた分は翌日として折り返す。
public func clockLabel(_ minute: Int) -> String {
    let wrapped = ((minute % 1440) + 1440) % 1440
    return String(format: "%02d:%02d", wrapped / 60, wrapped % 60)
}
