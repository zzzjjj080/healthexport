import Foundation
import HealthKit
import HealthExportCore

/// その項目に、その期間の記録があるか。
struct MetricAvailability: Sendable, Equatable {
    var hasData: Bool
    var sourceNames: [String]
    /// 「1件ずつ全部」にしたときの件数の目安。実際に書き出すまで正確な数は分からない。
    var estimatedSamples: Int
}

struct DailyReadResult: Sendable {
    var daily: [YMD: [MetricID: MetricValue]] = [:]
    var workouts: [WorkoutEvent] = []
    var deviceNames: [String] = []
}

/// ここだけがHealthKitを知っている層。
///
/// **読み取りの許可が下りたかどうかは、アプリからは分からない。**
/// プライバシー保護のため、拒否されていてもクエリは成功して0件を返す。
/// だから「記録なし」を「データが無い」と断定して見せてはいけない。
/// 画面には必ず「許可がオフの可能性」も併せて出すこと。
@MainActor
@Observable
final class HealthReader {

    private let store = HKHealthStore()

    /// 失敗した理由。**握り潰さない。**（引き継ぎ書 4-1）
    /// 無反応が一番たちが悪いので、必ず画面に出す。
    ///
    /// 1件だけ持つと、あとの失敗で最初の原因が消える。
    /// 最初に起きたことのほうが本当の原因であることが多いので、全部ためる。
    private(set) var errors: [String] = []

    var lastError: String? { errors.first }

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func clearError() { errors.removeAll() }

    private func note(_ message: String) {
        guard !errors.contains(message) else { return }   // 同じものを何度も並べない
        errors.append(message)
    }

    // MARK: - 型の変換

    /// Coreが持っている識別子の文字列を、HealthKitの型に変える。
    func objectType(for metric: Metric) -> HKObjectType? {
        switch metric.source {
        case .quantity(let identifier, _, _):
            return HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier))
        case .category(let identifier):
            return HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier))
        case .workout:
            return HKObjectType.workoutType()
        case .stateOfMind:
            if #available(iOS 18.0, *) { return HKObjectType.stateOfMindType() }
            return nil
        }
    }

    private func quantityType(_ metric: Metric) -> (type: HKQuantityType, unit: HKUnit, scale: Double)? {
        guard case .quantity(let identifier, let unitString, let scale) = metric.source,
              let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier))
        else { return nil }
        return (type, HKUnit(from: unitString), scale)
    }

    private func datePredicate(_ range: DateRange) -> NSPredicate? {
        guard let start = range.from.dayBounds()?.start,
              let end = range.to.dayBounds()?.end else { return nil }
        return HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
    }

    // MARK: - 許可

    /// 読み取りの許可をまとめて求める。
    ///
    /// 全項目ぶんを一度に求める。あとから足すと、そのたびにダイアログが出て煩わしい。
    func requestAuthorization() async -> Bool {
        guard Self.isAvailable else {
            note("この端末ではヘルスケアを使えません。")
            return false
        }
        let types = Set(MetricCatalog.all.compactMap { objectType(for: $0) })
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            errors.removeAll()
            return true
        } catch {
            // ここで握り潰すと、ボタンを押しても無反応になって原因が分からなくなる
            note("ヘルスケアの許可を求められませんでした: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 何が取れるかを調べる

    /// 期間内に記録がある項目を調べる。
    /// 端末の申告は求めない。**実際に記録があるかどうかは、読めば分かる。**
    func scan(range: DateRange) async -> [MetricID: MetricAvailability] {
        guard let predicate = datePredicate(range) else { return [:] }
        var result: [MetricID: MetricAvailability] = [:]
        for metric in MetricCatalog.all {
            result[metric.id] = await availability(of: metric, predicate: predicate, days: range.dayCount)
        }
        return result
    }

    private func availability(of metric: Metric, predicate: NSPredicate, days: Int) async -> MetricAvailability {
        let empty = MetricAvailability(hasData: false, sourceNames: [], estimatedSamples: 0)
        do {
            let names: [String]
            switch metric.source {
            case .quantity:
                guard let (type, _, _) = quantityType(metric) else { return empty }
                let sources = try await HKSourceQueryDescriptor(
                    predicate: .quantitySample(type: type, predicate: predicate)).result(for: store)
                names = sources.map(\.name)
            case .category(let identifier):
                guard let type = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier))
                else { return empty }
                let sources = try await HKSourceQueryDescriptor(
                    predicate: .categorySample(type: type, predicate: predicate)).result(for: store)
                names = sources.map(\.name)
            case .workout:
                let sources = try await HKSourceQueryDescriptor(
                    predicate: .workout(predicate)).result(for: store)
                names = sources.map(\.name)
            case .stateOfMind:
                guard #available(iOS 18.0, *) else { return empty }
                let sources = try await HKSourceQueryDescriptor(
                    predicate: .stateOfMind(predicate)).result(for: store)
                names = sources.map(\.name)
            }
            guard !names.isEmpty else { return empty }
            return MetricAvailability(hasData: true,
                                      sourceNames: names.sorted(),
                                      estimatedSamples: metric.samplesPerDay * days)
        } catch {
            note("\(metric.jaName)を調べられませんでした: \(error.localizedDescription)")
            return empty
        }
    }

    // MARK: - 日ごとの値を読む

    /// - Parameter progress: 何番目のどの項目を読んでいるかを知らせる。
    ///   24項目を1年ぶん読むと十数秒かかるので、進みを見せないと固まったように見える。
    func readDaily(range: DateRange, metrics: [Metric],
                   progress: ((Int, Int, String) -> Void)? = nil) async -> DailyReadResult {
        var result = DailyReadResult()
        var names: Set<String> = []
        guard let predicate = datePredicate(range) else { return result }

        for (index, metric) in metrics.enumerated() {
            progress?(index + 1, metrics.count, metric.jaName)
            switch metric.aggregation {
            case .sum, .average, .minMaxAverage, .latest:
                if metric.source.isQuantity {
                    await readQuantity(metric, range: range, into: &result)
                } else {
                    await readCategoryDuration(metric, range: range, predicate: predicate, into: &result)
                }
            case .sleep:
                await readSleep(metric, range: range, into: &result)
            case .workoutList:
                await readWorkouts(range: range, predicate: predicate, into: &result, names: &names)
            case .moodLatest:
                await readStateOfMind(metric, predicate: predicate, into: &result)
            }
        }

        // 端末の名前は、実際に書き込んでいたソースから集める
        let availability = await scan(range: range)
        for metric in metrics {
            availability[metric.id]?.sourceNames.forEach { names.insert($0) }
        }
        result.deviceNames = names.sorted()
        return result
    }

    private func readQuantity(_ metric: Metric, range: DateRange, into result: inout DailyReadResult) async {
        guard let (type, unit, scale) = quantityType(metric),
              let start = range.from.dayBounds()?.start,
              let end = range.to.dayBounds()?.end else { return }
        let options: HKStatisticsOptions
        switch metric.aggregation {
        case .sum:            options = .cumulativeSum
        case .minMaxAverage:  options = [.discreteAverage, .discreteMin, .discreteMax]
        default:              options = .discreteAverage
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: options,
            anchorDate: start,
            intervalComponents: DateComponents(day: 1))
        do {
            let collection = try await descriptor.result(for: store)
            for statistics in collection.statistics() {
                let day = YMD.from(statistics.startDate)
                guard day >= range.from, day <= range.to else { continue }
                let value: MetricValue?
                switch metric.aggregation {
                case .sum:
                    value = statistics.sumQuantity().map { .number($0.doubleValue(for: unit) * scale) }
                case .minMaxAverage:
                    if let average = statistics.averageQuantity(),
                       let low = statistics.minimumQuantity(),
                       let high = statistics.maximumQuantity() {
                        value = .stats(average: average.doubleValue(for: unit) * scale,
                                       min: low.doubleValue(for: unit) * scale,
                                       max: high.doubleValue(for: unit) * scale)
                    } else { value = nil }
                default:
                    value = statistics.averageQuantity().map { .number($0.doubleValue(for: unit) * scale) }
                }
                if let value { result.daily[day, default: [:]][metric.id] = value }
            }
        } catch {
            note("\(metric.jaName)を読めませんでした: \(error.localizedDescription)")
        }
    }

    /// マインドフルネスのように「区間の長さを足す」カテゴリ。
    private func readCategoryDuration(_ metric: Metric, range: DateRange,
                                      predicate: NSPredicate, into result: inout DailyReadResult) async {
        guard case .category(let identifier) = metric.source,
              let type = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier))
        else { return }
        do {
            let samples = try await HKSampleQueryDescriptor(
                predicates: [.categorySample(type: type, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)]).result(for: store)
            var minutes: [YMD: Double] = [:]
            for sample in samples {
                let day = YMD.from(sample.startDate)
                minutes[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate) / 60
            }
            for (day, value) in minutes where day >= range.from && day <= range.to {
                result.daily[day, default: [:]][metric.id] = .number(value)
            }
        } catch {
            note("\(metric.jaName)を読めませんでした: \(error.localizedDescription)")
        }
    }

    // MARK: - 睡眠

    /// 睡眠は日をまたぐので、**起きた日に属させる。**（ヘルスケアの見せ方と同じ）
    /// 夕方6時を境にして、それ以降に終わった睡眠は翌日ぶんとして扱う（夕方の仮眠を翌日に送らないため）。
    private func sleepDay(for date: Date) -> YMD {
        let hour = YMD.calendar.component(.hour, from: date)
        let day = YMD.from(date)
        return hour >= 18 ? day.adding(days: 1) : day
    }

    private func minuteOfDay(_ date: Date) -> Int {
        YMD.calendar.component(.hour, from: date) * 60 + YMD.calendar.component(.minute, from: date)
    }

    private enum SleepStage { case deep, rem, core, awake }

    private func stage(of sample: HKCategorySample) -> SleepStage? {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return nil }
        switch value {
        case .inBed:                          return nil   // 眠っている区間と重なるので数えない
        case .awake:                          return .awake
        case .asleepDeep:                     return .deep
        case .asleepREM:                      return .rem
        case .asleepCore, .asleepUnspecified: return .core
        @unknown default:                     return nil
        }
    }

    private func sleepSamples(range: DateRange) async throws -> [HKCategorySample] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
              // 前夜からの睡眠を取りこぼさないよう、1日ぶん前から読む
              let start = range.from.adding(days: -1).dayBounds()?.start,
              let end = range.to.dayBounds()?.end else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        return try await HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]).result(for: store)
    }

    private func readSleep(_ metric: Metric, range: DateRange, into result: inout DailyReadResult) async {
        do {
            let samples = try await sleepSamples(range: range)
            var byDay: [YMD: [SleepStage: [IntervalMath.Interval]]] = [:]
            for sample in samples {
                guard let stage = stage(of: sample) else { continue }
                let day = sleepDay(for: sample.endDate)
                let interval = IntervalMath.Interval(start: sample.startDate, end: sample.endDate)
                byDay[day, default: [:]][stage, default: []].append(interval)
            }
            for (day, stages) in byDay where day >= range.from && day <= range.to {
                let asleep = (stages[.deep] ?? []) + (stages[.rem] ?? []) + (stages[.core] ?? [])
                guard !asleep.isEmpty else { continue }
                // 端末が2つあると同じ夜を二重に記録するので、必ず重なりを潰してから足す
                let summary = SleepSummary(
                    total: IntervalMath.totalMinutes(asleep) / 60,
                    deep: IntervalMath.totalMinutes(stages[.deep] ?? []) / 60,
                    rem: IntervalMath.totalMinutes(stages[.rem] ?? []) / 60,
                    core: IntervalMath.totalMinutes(stages[.core] ?? []) / 60,
                    awake: IntervalMath.totalMinutes(stages[.awake] ?? []) / 60,
                    bedMinute: IntervalMath.earliestStart(asleep).map(minuteOfDay),
                    wakeMinute: IntervalMath.latestEnd(asleep).map(minuteOfDay))
                result.daily[day, default: [:]][metric.id] = .sleep(summary)
            }
        } catch {
            note("睡眠を読めませんでした: \(error.localizedDescription)")
        }
    }

    // MARK: - 1件ずつ全部

    /// 一度に持つ上限。心拍を1年ぶん選ぶと数十万件になり、そのまま持つと落ちる。
    static let rawSampleLimit = 50_000

    /// 「1件ずつ全部」を選んだ項目を読む。心拍は3ヶ月で10万件を超えるので、時間がかかる。
    ///
    /// - Parameter estimatedTotal: 期間内にあると見込まれる件数。
    ///   上限で切ったときに「本当は何件あったか」を書き出しに残すために使う。
    func readRaw(metric: Metric, range: DateRange, estimatedTotal: Int = 0) async -> RawSeries? {
        guard let predicate = datePredicate(range) else { return nil }
        do {
            if metric.aggregation == .sleep {
                let samples = try await sleepSamples(range: range)
                var segments: [SleepSegment] = []
                for sample in samples {
                    guard let stage = stage(of: sample) else { continue }
                    let day = sleepDay(for: sample.endDate)
                    guard day >= range.from, day <= range.to else { continue }
                    let names = Self.stageNames(stage)
                    segments.append(SleepSegment(day: YMD.from(sample.startDate),
                                                 startMinute: minuteOfDay(sample.startDate),
                                                 endMinute: minuteOfDay(sample.endDate),
                                                 stageJa: names.ja, stageEn: names.en))
                }
                return .sleepSegments(segments, total: segments.count)
            }
            guard let (type, unit, scale) = quantityType(metric) else { return nil }
            let samples = try await HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: type, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)],
                limit: Self.rawSampleLimit).result(for: store)
            let values = samples.map {
                RawSample(day: YMD.from($0.startDate),
                          minute: minuteOfDay($0.startDate),
                          value: $0.quantity.doubleValue(for: unit) * scale)
            }
            // 上限ちょうどで返ってきたら、まだ先がある。見込みの件数のほうを総数として残す
            let total = samples.count < Self.rawSampleLimit
                ? samples.count
                : max(estimatedTotal, samples.count)
            return .numbers(values, total: total)
        } catch {
            note("\(metric.jaName)の詳細を読めませんでした: \(error.localizedDescription)")
            return nil
        }
    }

    private static func stageNames(_ stage: SleepStage) -> (ja: String, en: String) {
        switch stage {
        case .deep:  return ("深い", "deep")
        case .rem:   return ("レム", "REM")
        case .core:  return ("コア", "core")
        case .awake: return ("覚醒", "awake")
        }
    }

    private func readWorkouts(range: DateRange, predicate: NSPredicate,
                              into result: inout DailyReadResult, names: inout Set<String>) async {
        do {
            let workouts = try await HKSampleQueryDescriptor(
                predicates: [.workout(predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)]).result(for: store)
            let calendar = YMD.calendar
            for workout in workouts {
                let day = YMD.from(workout.startDate)
                guard day >= range.from, day <= range.to else { continue }
                let startMinute = calendar.component(.hour, from: workout.startDate) * 60
                    + calendar.component(.minute, from: workout.startDate)
                let energy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                    .sumQuantity()?.doubleValue(for: .kilocalorie())
                let heartRate = workout.statistics(for: HKQuantityType(.heartRate))?
                    .averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                result.workouts.append(WorkoutEvent(
                    day: day,
                    startMinute: startMinute,
                    minutes: Int((workout.duration / 60).rounded()),
                    kilocalories: energy,
                    averageHeartRate: heartRate,
                    kindJa: WorkoutNames.name(workout.workoutActivityType, language: .ja),
                    kindEn: WorkoutNames.name(workout.workoutActivityType, language: .en)))
                names.insert(workout.sourceRevision.source.name)
            }
        } catch {
            note("ワークアウトを読めませんでした: \(error.localizedDescription)")
        }
    }

    private func readStateOfMind(_ metric: Metric, predicate: NSPredicate,
                                 into result: inout DailyReadResult) async {
        guard #available(iOS 18.0, *) else { return }
        do {
            let samples = try await HKSampleQueryDescriptor(
                predicates: [.stateOfMind(predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)]).result(for: store)
            for sample in samples {
                let day = YMD.from(sample.startDate)
                let label = Self.valenceLabel(sample.valenceClassification)
                result.daily[day, default: [:]][metric.id] = .bilingual(ja: label.ja, en: label.en)
            }
        } catch {
            note("気分の記録を読めませんでした: \(error.localizedDescription)")
        }
    }

    /// 気分の言い表し方。**日英の両方を返す。**
    /// 読み出す時点では、どちらの言語で書き出すか決まっていない。
    @available(iOS 18.0, *)
    static func valenceLabel(_ classification: HKStateOfMind.ValenceClassification) -> (ja: String, en: String) {
        switch classification {
        case .veryUnpleasant:     return ("とても不快", "very unpleasant")
        case .unpleasant:         return ("不快", "unpleasant")
        case .slightlyUnpleasant: return ("やや不快", "slightly unpleasant")
        case .neutral:            return ("ふつう", "neutral")
        case .slightlyPleasant:   return ("やや快い", "slightly pleasant")
        case .pleasant:           return ("快い", "pleasant")
        case .veryPleasant:       return ("とても快い", "very pleasant")
        @unknown default:         return ("ふつう", "neutral")
        }
    }
}

private extension HealthSource {
    var isQuantity: Bool {
        if case .quantity = self { return true }
        return false
    }
}
