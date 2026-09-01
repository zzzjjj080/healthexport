#if DEBUG
import Foundation
import HealthExportCore

/// シミュレータにはヘルスケアの記録が無いので、確認とスクリーンショットのために擬似の記録を作る。
///
/// **リリースビルドには入らない。** `#if DEBUG` に加えて環境変数でも守る。
/// 入っていないことは `strings` で必ず確かめること。（引き継ぎ書 4-7）
///
///     SIMCTL_CHILD_HEALTHEXPORT_DEMO=1 xcrun simctl launch booted com.zzzjjj080.HealthExport
enum DemoData {

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["HEALTHEXPORT_DEMO"] == "1"
    }

    /// 持っている端末で取れるものだけを「あり」にする。
    private static let sources: [MetricID: [String]] = {
        let phone = ["iPhone"]
        let watch = ["Apple Watch"]
        let both = ["Apple Watch", "iPhone"]
        var table: [MetricID: [String]] = [:]
        for id in MetricID.allCases {
            switch id {
            case .steps, .distance, .flights:                     table[id] = both
            case .walkingSpeed, .stepLength, .walkingAsymmetry:   table[id] = phone
            case .stateOfMind:                                    table[id] = phone
            case .headphoneAudio:                                 table[id] = ["AirPods Pro"]
            case .bodyMass, .bodyFat:                             continue   // 体組成計は持っていない想定
            default:                                              table[id] = watch
            }
        }
        return table
    }()

    // 日付とキーで決まる擬似乱数。起動しなおしても同じ値が出る
    private static func noise(_ id: String, _ day: YMD, _ key: String = "") -> Double {
        var hash: UInt32 = 2166136261
        for byte in Array("\(id)|\(day.iso)|\(key)".utf8) {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        return Double(hash % 100_000) / 100_000
    }

    static func availability(range: DateRange) -> [MetricID: MetricAvailability] {
        var result: [MetricID: MetricAvailability] = [:]
        for metric in MetricCatalog.all {
            if let names = sources[metric.id] {
                result[metric.id] = MetricAvailability(hasData: true, sourceNames: names,
                                                       estimatedSamples: metric.samplesPerDay * range.dayCount)
            } else {
                result[metric.id] = MetricAvailability(hasData: false, sourceNames: [], estimatedSamples: 0)
            }
        }
        return result
    }

    static func read(range: DateRange, metrics: [Metric]) -> DailyReadResult {
        var result = DailyReadResult()
        result.deviceNames = ["Apple Watch", "AirPods Pro", "iPhone"]
        for day in range.days {
            for metric in metrics {
                guard sources[metric.id] != nil else { continue }
                switch metric.aggregation {
                case .workoutList:
                    guard noise(metric.id.rawValue, day) < 0.42 else { continue }
                    let kinds = [("ウォーキング", "Walking"), ("ランニング", "Running"),
                                 ("サイクリング", "Cycling"), ("筋力トレーニング", "Strength training")]
                    let kind = kinds[Int(noise(metric.id.rawValue, day, "k") * Double(kinds.count))]
                    let minutes = Int(18 + noise(metric.id.rawValue, day, "m") * 62)
                    result.workouts.append(WorkoutEvent(
                        day: day,
                        startMinute: Int(6 * 60 + noise(metric.id.rawValue, day, "s") * 13 * 60),
                        minutes: minutes,
                        kilocalories: Double(minutes) * (4 + noise(metric.id.rawValue, day, "c") * 4),
                        averageHeartRate: 112 + noise(metric.id.rawValue, day, "h") * 30,
                        kindJa: kind.0, kindEn: kind.1))
                case .sleep:
                    let total = 6.2 + noise(metric.id.rawValue, day, "t") * 2.2
                    let deep = total * (0.12 + noise(metric.id.rawValue, day, "d") * 0.07)
                    let rem = total * (0.18 + noise(metric.id.rawValue, day, "r") * 0.08)
                    result.daily[day, default: [:]][metric.id] = .sleep(SleepSummary(
                        total: total, deep: deep, rem: rem, core: total - deep - rem,
                        awake: 0.2 + noise(metric.id.rawValue, day, "a") * 0.5,
                        bedMinute: Int(22 * 60 + noise(metric.id.rawValue, day, "b") * 150),
                        wakeMinute: Int(5 * 60 + noise(metric.id.rawValue, day, "w") * 180)))
                case .moodLatest:
                    guard noise(metric.id.rawValue, day, "mood") < 0.5 else { continue }
                    let labels = ["とても快い", "快い", "やや快い", "ふつう", "やや不快", "不快"]
                    let labelsEn = ["very pleasant", "pleasant", "slightly pleasant", "neutral", "slightly unpleasant", "unpleasant"]
                    let index = Int(noise(metric.id.rawValue, day) * Double(labels.count))
                    result.daily[day, default: [:]][metric.id] =
                        .bilingual(ja: labels[index], en: labelsEn[index])
                case .minMaxAverage:
                    let base = center(metric)
                    let average = base + (noise(metric.id.rawValue, day) - 0.5) * spread(metric) * 2
                    result.daily[day, default: [:]][metric.id] = .stats(
                        average: average,
                        min: average - (14 + noise(metric.id.rawValue, day, "n") * 10),
                        max: average + (48 + noise(metric.id.rawValue, day, "x") * 46))
                default:
                    let value = center(metric) + (noise(metric.id.rawValue, day) - 0.5) * spread(metric) * 2
                    result.daily[day, default: [:]][metric.id] = .number(max(0, value))
                }
            }
        }
        return result
    }

    static func rawSeries(metric: Metric, range: DateRange) -> RawSeries {
        var samples: [RawSample] = []
        for day in range.days {
            for index in 0..<metric.samplesPerDay {
                let minute = index * 1440 / metric.samplesPerDay
                let circadian = sin(Double(minute - 360) / 1440 * .pi * 2)
                samples.append(RawSample(day: day, minute: minute,
                                         value: center(metric) + circadian * spread(metric) * 0.5
                                              + (noise(metric.id.rawValue, day, "r\(index)") - 0.5) * spread(metric)))
            }
        }
        return .numbers(samples, total: samples.count)
    }

    private static func center(_ metric: Metric) -> Double {
        switch metric.id {
        case .steps: return 8000
        case .distance: return 5.8
        case .flights: return 9
        case .activeEnergy: return 520
        case .basalEnergy: return 1620
        case .exerciseTime: return 34
        case .standTime: return 620
        case .heartRate: return 72
        case .restingHeartRate: return 56
        case .hrv: return 42
        case .walkingHeartRate: return 104
        case .vo2Max: return 38.5
        case .oxygenSaturation: return 97
        case .respiratoryRate: return 14.5
        case .wristTemperature: return 0
        case .walkingSpeed: return 4.6
        case .stepLength: return 71
        case .walkingAsymmetry: return 1.4
        case .headphoneAudio: return 73
        case .environmentalAudio: return 58
        case .mindful: return 6
        default: return 1
        }
    }

    private static func spread(_ metric: Metric) -> Double {
        switch metric.id {
        case .steps: return 3500
        case .distance: return 2.6
        case .flights: return 7
        case .activeEnergy: return 230
        case .basalEnergy: return 90
        case .exerciseTime: return 26
        case .standTime: return 120
        case .heartRate: return 8
        case .restingHeartRate: return 4
        case .hrv: return 14
        case .walkingHeartRate: return 9
        case .vo2Max: return 1.5
        case .oxygenSaturation: return 1.2
        case .respiratoryRate: return 1.3
        case .wristTemperature: return 0.45
        case .walkingSpeed: return 0.4
        case .stepLength: return 4
        case .walkingAsymmetry: return 1.1
        case .headphoneAudio: return 7
        case .environmentalAudio: return 9
        case .mindful: return 6
        default: return 1
        }
    }
}
#endif
