import Foundation
import HealthExportCore

extension Language {
    /// 画面の言語。端末の設定に従う。
    /// **書き出すテキストの言語（設定で選ぶ）とは別物。**
    static var ui: Language { Language.forLocale() }
}

/// 数字や単位が混ざる文言は String Catalog では拾えないので、コードで言語ごとに組む。
/// （引き継ぎ書 4-87）文字通りの `Text("…")` はカタログに任せ、こちらは使わない。
func L(_ ja: String, _ en: String) -> String {
    Language.ui == .ja ? ja : en
}
