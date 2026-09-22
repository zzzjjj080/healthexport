import SwiftUI
import UIKit

/// 書き出した本文を、表として読める形で見せる。
///
/// 2つの理由でUIKitを使う。
/// 1. SwiftUIの `Text` はタブに幅を持たないので、表が `83895.26658` のように潰れる。
/// 2. `UITextView` は contentSize を自前で管理するため、折り返しを切っても横へスクロールしない。
///
/// なので **UIScrollView に UILabel を1枚置く。** 幅は中身を測って決める。
struct MonospacedTextView: UIViewRepresentable {
    let text: String

    private static let inset: CGFloat = 14
    private static let labelTag = 71

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        // 表は左から右に並べる。アラビア語の端末では画面全体が右から左になり、
        // そのままだと本文が右端へ寄って上半分が空白になり、表の列も左右が入れ替わった。
        // 本文そのもの（コピーされるもの）は正しいので、見せ方だけ左からに固定する。（引き継ぎ書 4-179）
        scroll.semanticContentAttribute = .forceLeftToRight
        scroll.backgroundColor = .secondarySystemGroupedBackground
        scroll.alwaysBounceVertical = true
        scroll.alwaysBounceHorizontal = true
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = true
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byClipping
        label.tag = Self.labelTag
        label.semanticContentAttribute = .forceLeftToRight
        label.textAlignment = .left
        scroll.addSubview(label)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        guard let label = scroll.viewWithTag(Self.labelTag) as? UILabel else { return }
        let font = Self.font(for: text)
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byClipping
        style.baseWritingDirection = .leftToRight
        style.alignment = .left
        style.tabStops = Self.tabStops(for: text, font: font)
        style.defaultTabInterval = font.pointSize * 6
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .paragraphStyle: style,
            .foregroundColor: UIColor.label,
        ])
        let size = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                             height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: Self.inset, y: Self.inset, width: size.width, height: size.height)
        scroll.contentSize = CGSize(width: size.width + Self.inset * 2,
                                    height: size.height + Self.inset * 2)
    }

    /// 等幅の字形はアラビア文字をつなげて書けず、1文字ずつばらばらに並ぶ。
    /// アラビア文字が入るときだけ、数字だけ等幅の標準の字形にする。
    /// 列はタブ位置を実際に測って揃えているので、字形が等幅でなくても表は崩れない。
    private static func font(for text: String) -> UIFont {
        let hasArabic = text.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
        return hasArabic
            ? UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            : UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    }

    /// 列の中身を実際に測ってタブ位置を決める。
    ///
    /// 等間隔に置くと、日本語の長い列名（「アクティブエネルギー(kcal)」など）が
    /// 幅を超えて次の値と詰まる。**列ごとに必要な幅は違う**ので、測るしかない。
    private static func tabStops(for text: String, font: UIFont) -> [NSTextTab] {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        var widths: [CGFloat] = []
        var measured = 0
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard line.contains("\t") else { continue }
            measured += 1
            if measured > 400 { break }   // 全部測ると重い。頭のほうで足りる
            for (index, cell) in line.split(separator: "\t", omittingEmptySubsequences: false).enumerated() {
                let width = (String(cell) as NSString).size(withAttributes: attributes).width
                if index < widths.count {
                    widths[index] = max(widths[index], width)
                } else {
                    widths.append(width)
                }
            }
        }
        var stops: [NSTextTab] = []
        var location: CGFloat = 0
        let gap = font.pointSize * 1.4
        for width in widths.dropLast() {
            location += width + gap
            stops.append(NSTextTab(textAlignment: .left, location: location))
        }
        return stops
    }
}
