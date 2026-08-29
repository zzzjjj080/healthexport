import SwiftUI
import UIKit

/// 書き出した本文を、表として読める形で見せる。
///
/// SwiftUIの `Text` はタブに幅を持たせないので、
/// タブ区切りの表が `83895.26658` のように潰れて見える。
/// 桁の位置がずれると「壊れている」ように見えるため、ここだけUIKitを使う。
struct MonospacedTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.alwaysBounceHorizontal = true
        view.showsHorizontalScrollIndicator = true
        view.backgroundColor = UIColor.secondarySystemGroupedBackground
        view.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        // 折り返さずに横へ伸ばす
        view.textContainer.lineBreakMode = .byClipping
        view.textContainer.widthTracksTextView = false
        view.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude,
                                         height: CGFloat.greatestFiniteMagnitude)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byClipping
        // タブ位置を等間隔に置く。これが無いと列がそろわない
        let interval: CGFloat = font.pointSize * 6
        style.defaultTabInterval = interval
        style.tabStops = (1...60).map {
            NSTextTab(textAlignment: .left, location: CGFloat($0) * interval)
        }
        view.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .paragraphStyle: style,
            .foregroundColor: UIColor.label,
        ])
    }
}
