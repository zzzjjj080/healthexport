import SwiftUI

/// 初回だけ出す説明。
/// 毎回いちばん上を占領されると、2回目からは邪魔になる。
struct IntroSheet: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            VStack(spacing: 14) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Palette.accentGradient)
                Text("ヘルスケアの記録を、\nAIに渡せる文章に。")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 22) {
                step("1", "目的を選ぶ", "期間も項目も、AIへの依頼文も、それだけで決まります。",
                     symbol: "square.grid.2x2.fill")
                step("2", "書き出す", "ヘルスケアから読んで、1枚のテキストにまとめます。",
                     symbol: "square.and.arrow.up.on.square.fill")
                step("3", "AIに渡す", "そのままチャット欄に貼るか、ファイルとして送ります。",
                     symbol: "doc.on.doc.fill")
            }
            .padding(.horizontal, 30)

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Text("読み取ったデータは端末の中だけで扱います。\nこのアプリが外部に送ることはありません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: onStart) {
                    Text("はじめる")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Palette.accentGradient))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("introStartButton")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func step(_ number: String, _ title: String, _ detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(Palette.accent.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// チップを行に詰めて、あふれたら折り返すだけの並べ方。
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
