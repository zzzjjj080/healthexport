import Foundation

public enum Language: String, Codable, Sendable, CaseIterable {
    case ja, en
    case zhHans = "zh-Hans", zhHant = "zh-Hant"
    case ko, es, fr, de, it
    case ptBR = "pt-BR"
    case ru, ar

    /// 訳が無いときに落ちる先。英語は必ず全項目そろえてある。
    public static let fallback: Language = .en

    /// 右から左へ書く言語。画面の向きを変える必要がある。
    public var isRightToLeft: Bool { self == .ar }

    /// この言語での言語名（設定の一覧に出す）。
    public var endonym: String {
        switch self {
        case .ja: return "日本語"
        case .en: return "English"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .ko: return "한국어"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        case .ptBR: return "Português (Brasil)"
        case .ru: return "Русский"
        case .ar: return "العربية"
        }
    }

    /// 端末の言語から決める。訳を持たない言語は英語にする。
    ///
    /// 中国語とポルトガル語は、地域まで見ないと簡体字か繁体字か、ブラジルか欧州かが決まらない。
    /// `languageCode` だけで振り分けると、台湾の端末に簡体字を出してしまう。（引き継ぎ書 4-158）
    /// 引数で `Locale` を受けておくと、全言語をテストで固定できる。（4-87）
    public static func forLocale(_ locale: Locale = .current) -> Language {
        guard let code = locale.language.languageCode?.identifier else { return fallback }
        switch code {
        case "zh":
            // 繁体字は台湾・香港・マカオ。文字体系が取れればそれを優先する。
            if let script = locale.language.script?.identifier {
                return script == "Hant" ? .zhHant : .zhHans
            }
            let region = locale.language.region?.identifier ?? ""
            return ["TW", "HK", "MO"].contains(region) ? .zhHant : .zhHans
        case "pt":
            // ブラジル以外のポルトガル語は、訳を持たないので英語にする。
            return locale.language.region?.identifier == "BR" ? .ptBR : fallback
        default:
            return Language(rawValue: code) ?? fallback
        }
    }
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
    /// 言葉で表す値を、**訳ではなくキーで持つ**（気分の記録の "neutral" など）。
    /// 読み出した時点では書き出す言語が決まっていないので、訳を焼き付けてしまうと
    /// あとから言語を切り替えたときに1列だけ前の言語のまま残る。
    case localized(key: String, table: LocalizedTable)
    /// 日数。生理を週・月にまとめたときの「出血のあった日数」。言葉は書き出す言語で付ける
    case dayCount(Int)

    /// `localized` がどの表を引くか。表そのものを値に持たせると Equatable が重くなる。
    public enum LocalizedTable: String, Equatable, Sendable {
        case mood
        case flow
    }
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
///
/// 種目は **名前ではなくキーで持つ**（`HKWorkoutActivityType` のケース名。"running" など）。
/// アプリ層が名前を12言語ぶん埋めて渡すのは現実的でないし、書き出す言語を
/// 切り替えるたびに読み直す羽目になる。Core が種目番号を解釈することもしない。
public struct WorkoutEvent: Equatable, Sendable {
    public let day: YMD
    public let startMinute: Int
    public let minutes: Int
    public let kilocalories: Double?
    public let averageHeartRate: Double?
    public let kindKey: String

    public init(day: YMD, startMinute: Int, minutes: Int, kilocalories: Double? = nil,
                averageHeartRate: Double? = nil, kindKey: String) {
        self.day = day
        self.startMinute = startMinute
        self.minutes = minutes
        self.kilocalories = kilocalories
        self.averageHeartRate = averageHeartRate
        self.kindKey = kindKey
    }

    public func kind(_ language: Language) -> String { Tr.get(Tr.workout, kindKey, language) }
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
///
/// 段階は日ごとの表の列名（deep / rem / core / awake）と同じ語なので、同じ表から引く。
/// 二重に訳を持つと、片方だけ直したときに表と一覧で呼び名が食い違う。
public struct SleepSegment: Equatable, Sendable {
    public let day: YMD
    public let startMinute: Int
    public let endMinute: Int
    public let stageKey: String

    public init(day: YMD, startMinute: Int, endMinute: Int, stageKey: String) {
        self.day = day
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.stageKey = stageKey
    }

    public func stage(_ language: Language) -> String { Tr.get(Tr.keyLabel, stageKey, language) }
}

/// 「1件ずつ全部」で読んだ結果。
///
/// `total` は実際にあった件数。心拍を1年ぶん選ぶと数十万件になり、
/// そのまま持つと落ちるので、**上限で切ったうえで元の件数を覚えておく。**
/// 切ったことは書き出す本文にも書く。黙って減らすとAIが期間を誤解する。
public enum RawSeries: Equatable, Sendable {
    case numbers([RawSample], total: Int)
    case sleepSegments([SleepSegment], total: Int)

    /// 実際に持っている件数。
    public var count: Int {
        switch self {
        case .numbers(let s, _): return s.count
        case .sleepSegments(let s, _): return s.count
        }
    }

    /// もともとあった件数。
    public var total: Int {
        switch self {
        case .numbers(_, let t), .sleepSegments(_, let t): return t
        }
    }

    public var isTruncated: Bool { total > count }
}

/// 午前0時からの分を "HH:mm" にする。24時間を超えた分は翌日として折り返す。
public func clockLabel(_ minute: Int) -> String {
    let wrapped = ((minute % 1440) + 1440) % 1440
    return String(format: "%02d:%02d", wrapped / 60, wrapped % 60)
}
