import Foundation

/// 何のためにAIへ渡すか。
///
/// これを選ぶだけで、期間・項目・依頼文がまとめて決まる。
/// 「日ごとにまとめるか、1件ずつ全部か」を素人が判断できない以上、
/// **既定でうまくいく組み合わせを用意しておくのがアプリの仕事。**
public enum Purpose: String, CaseIterable, Codable, Sendable {
    case general, sleep, training, condition, mind, everything

    /// **どの目的でも、記録がある項目をすべて出す。**
    ///
    /// 以前は目的ごとに項目を絞っていたが、やめた（2026-09-25 本人判断）。
    /// 絞る理由が弱いため：日ごとにまとめれば全項目でも3ヶ月で2万字ほどにしかならないし、
    /// 何が効いているかは渡してみないと分からない（睡眠の話に食事や血圧が効くこともある）。
    /// **目的が決めるのは「AIへの聞き方」だけ**にして、選ぶ側の迷いを減らす。
    /// 項目を自分で絞りたい人は、詳しい設定から外せる。
    public var metricIDs: [MetricID]? { nil }

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
