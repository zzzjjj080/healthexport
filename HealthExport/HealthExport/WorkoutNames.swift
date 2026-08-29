import HealthKit
import HealthExportCore

/// ワークアウトの種目名。
///
/// `HKWorkoutActivityType` には名前を返すAPIが無いので、ここで対応表を持つ。
/// **番号ではなく列挙のケース名で書く。** 番号で書くとOSが種目を足したときに黙って間違える。
/// 表に無いものは「その他」。嘘の名前を出すより正しい。
enum WorkoutNames {

    static func name(_ type: HKWorkoutActivityType, language: Language) -> String {
        let pair = table[type]
        switch language {
        case .ja: return pair?.ja ?? "その他"
        case .en: return pair?.en ?? "Other"
        }
    }

    private static let table: [HKWorkoutActivityType: (ja: String, en: String)] = [
        .walking:                       ("ウォーキング", "Walking"),
        .running:                       ("ランニング", "Running"),
        .cycling:                       ("サイクリング", "Cycling"),
        .hiking:                        ("ハイキング", "Hiking"),
        .swimming:                      ("スイミング", "Swimming"),
        .yoga:                          ("ヨガ", "Yoga"),
        .pilates:                       ("ピラティス", "Pilates"),
        .traditionalStrengthTraining:   ("筋力トレーニング", "Strength training"),
        .functionalStrengthTraining:    ("機能的筋力トレーニング", "Functional strength training"),
        .coreTraining:                  ("体幹トレーニング", "Core training"),
        .highIntensityIntervalTraining: ("HIIT", "HIIT"),
        .elliptical:                    ("エリプティカル", "Elliptical"),
        .rowing:                        ("ローイング", "Rowing"),
        .stairClimbing:                 ("階段昇降", "Stair climbing"),
        .stairs:                        ("ステップ", "Stairs"),
        .dance:                         ("ダンス", "Dance"),
        .cooldown:                      ("クールダウン", "Cooldown"),
        .flexibility:                   ("ストレッチ", "Flexibility"),
        .mixedCardio:                   ("有酸素運動", "Mixed cardio"),
        .tennis:                        ("テニス", "Tennis"),
        .golf:                          ("ゴルフ", "Golf"),
        .basketball:                    ("バスケットボール", "Basketball"),
        .soccer:                        ("サッカー", "Soccer"),
        .baseball:                      ("野球", "Baseball"),
        .badminton:                     ("バドミントン", "Badminton"),
        .tableTennis:                   ("卓球", "Table tennis"),
        .boxing:                        ("ボクシング", "Boxing"),
        .climbing:                      ("クライミング", "Climbing"),
        .skatingSports:                 ("スケート", "Skating"),
        .snowSports:                    ("スノースポーツ", "Snow sports"),
        .surfingSports:                 ("サーフィン", "Surfing"),
        .martialArts:                   ("武術", "Martial arts"),
        .mindAndBody:                   ("心と体", "Mind and body"),
        .preparationAndRecovery:        ("準備と回復", "Preparation and recovery"),
        .wheelchairWalkPace:            ("車椅子（ウォーキングペース）", "Wheelchair walk pace"),
        .wheelchairRunPace:             ("車椅子（ランニングペース）", "Wheelchair run pace"),
        .other:                         ("その他", "Other"),
    ]
}
