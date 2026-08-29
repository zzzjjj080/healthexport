import Foundation

/// 書き出したテキストがAIのチャット欄に入るかどうか。
public enum SizeVerdict: String, Sendable {
    case comfortable   // そのまま貼れる
    case heavy         // 貼れるが重い
    case tooLarge      // 多くのAIに貼れない
}

public struct SizeEstimate: Equatable, Sendable {
    public let characters: Int
    public let lines: Int
    public let approximateTokens: Int

    public var verdict: SizeVerdict {
        if approximateTokens > 190_000 { return .tooLarge }
        if approximateTokens > 60_000 { return .heavy }
        return .comfortable
    }

    /// トークン数はモデルによって変わるので、あくまで目安。
    /// 日本語は1文字がほぼ1トークン、英数字は3〜4文字で1トークンとして数える。
    public static func of(_ text: String) -> SizeEstimate {
        var ascii = 0
        var wide = 0
        for scalar in text.unicodeScalars {
            if scalar.value < 128 { ascii += 1 } else { wide += 1 }
        }
        let tokens = Int((Double(ascii) / 3.6).rounded()) + wide
        return SizeEstimate(characters: ascii + wide,
                            lines: text.isEmpty ? 0 : text.split(separator: "\n", omittingEmptySubsequences: false).count,
                            approximateTokens: tokens)
    }
}
