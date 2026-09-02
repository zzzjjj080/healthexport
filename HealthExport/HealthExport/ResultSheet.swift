import SwiftUI
import UIKit
import HealthExportCore

/// 書き出した本文を見せて、渡す手段を出す画面。
/// **何を渡すのかが見えること**が大事なので、本文はそのまま出す。
struct ResultSheet: View {
    @Bindable var model: ExportModel
    @Environment(\.dismiss) private var dismiss
    @State private var fileURL: URL?
    @State private var copied = false
    @State private var tipJar = TipJar(productID: TipJar.productID)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                MonospacedTextView(text: model.previewText)
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [Color(.separator).opacity(0.35), .clear],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 6)
                    }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("書き出したもの")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }.font(.body.weight(.medium))
                }
            }
            .onAppear { fileURL = model.writeTemporaryFile() }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            if let estimate = model.estimate {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    measure(estimate.characters.formatted(), "文字")
                    Rectangle().fill(Color(.separator).opacity(0.5)).frame(width: 1, height: 30)
                    measure("約" + estimate.approximateTokens.formatted(), "トークン")
                    Rectangle().fill(Color(.separator).opacity(0.5)).frame(width: 1, height: 30)
                    measure(estimate.lines.formatted(), "行")
                }
                verdictBanner(estimate.verdict)
            }
            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = model.exportedText
                    Haptics.finished()
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.4))
                        copied = false
                    }
                } label: {
                    Label(copied ? "コピーしました" : "コピー",
                          systemImage: copied ? "checkmark" : "doc.on.doc.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Palette.accentGradient))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("copyButton")

                if let fileURL {
                    ShareLink(item: fileURL) {
                        Label("共有", systemImage: "square.and.arrow.up")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Palette.accent.opacity(0.12)))
                    }
                    .accessibilityIdentifier("shareButton")
                }
            }
            Text("チャット欄に貼るなら「コピー」、ファイルで送るなら「共有」。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            // 役に立った直後がいちばん自然な置き場所。
            // 主張はさせない（書き出す前のメイン画面には置かない）
            CoffeeTipLink(tipJar: tipJar, tint: Palette.accent)
                .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }

    private func measure(_ value: String, _ unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func verdictBanner(_ verdict: SizeVerdict) -> some View {
        let tint = verdict == .comfortable ? Palette.good : Palette.caution
        let symbol = verdict == .comfortable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
        return Label(verdictText(verdict), systemImage: symbol)
            .font(.caption)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.12)))
    }

    private func verdictText(_ verdict: SizeVerdict) -> String {
        switch verdict {
        case .comfortable:
            return "この量なら、AIのチャット欄にそのまま貼れます。"
        case .heavy:
            return "貼れますが重めです。項目を減らすか期間を短くすると扱いやすくなります。"
        case .tooLarge:
            return "大きすぎます。期間を短くするか、「1件ずつ全部」にした項目を「1日ごと」に戻してください。"
        }
    }
}
