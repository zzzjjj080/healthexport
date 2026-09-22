import Foundation
import HealthExportCore

extension Language {
    /// 画面の言語。端末の設定に従う。
    /// **書き出すテキストの言語（設定で選ぶ）とは別物。**
    static var ui: Language { Language.forLocale() }
}

// 以前あった `L(ja, en)`（日本語と英語をコードに直書きして選ぶヘルパ）は廃止した。
// 2言語しか扱えず、訳を足すたびにコードを触ることになるため。
// 数字や名前が混ざる文言も `String(localized: "…")` にすれば String Catalog が
// `%lld` `%@` の形で受け取れる。（引き継ぎ書 4-178）
