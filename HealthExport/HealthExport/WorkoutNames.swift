import HealthKit
import HealthExportCore

/// ワークアウトの種目名。
///
/// `HKWorkoutActivityType` には名前を返すAPIが無いので、ここで対応表を持つ。
/// **番号ではなく列挙のケース名で書く。** 番号で書くとOSが種目を足したときに黙って間違える。
/// 表が持つのは名前ではなくキーで、訳は Translations.json 側にある。
enum WorkoutNames {

    /// 種目を表すキー。**訳ではなくキーを返す。**
    /// 訳は Translations.json（12言語）にあり、書き出すときの言語で引く。
    /// 表に無いものは "other"。嘘の名前を出すより正しい。
    static func key(_ type: HKWorkoutActivityType) -> String {
        table[type] ?? "other"
    }

    private static let table: [HKWorkoutActivityType: String] = [
        .walking:                         "walking",
        .running:                         "running",
        .cycling:                         "cycling",
        .hiking:                          "hiking",
        .swimming:                        "swimming",
        .yoga:                            "yoga",
        .pilates:                         "pilates",
        .traditionalStrengthTraining:     "traditionalStrengthTraining",
        .functionalStrengthTraining:      "functionalStrengthTraining",
        .coreTraining:                    "coreTraining",
        .highIntensityIntervalTraining:   "highIntensityIntervalTraining",
        .elliptical:                      "elliptical",
        .rowing:                          "rowing",
        .stairClimbing:                   "stairClimbing",
        .stairs:                          "stairs",
        .dance:                           "dance",
        .cooldown:                        "cooldown",
        .flexibility:                     "flexibility",
        .mixedCardio:                     "mixedCardio",
        .tennis:                          "tennis",
        .golf:                            "golf",
        .basketball:                      "basketball",
        .soccer:                          "soccer",
        .baseball:                        "baseball",
        .badminton:                       "badminton",
        .tableTennis:                     "tableTennis",
        .boxing:                          "boxing",
        .climbing:                        "climbing",
        .skatingSports:                   "skatingSports",
        .snowSports:                      "snowSports",
        .surfingSports:                   "surfingSports",
        .martialArts:                     "martialArts",
        .mindAndBody:                     "mindAndBody",
        .preparationAndRecovery:          "preparationAndRecovery",
        .wheelchairWalkPace:              "wheelchairWalkPace",
        .wheelchairRunPace:               "wheelchairRunPace",
        .other:                           "other",
    ]
}
