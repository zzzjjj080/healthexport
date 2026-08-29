import SwiftUI
import UIKit
import HealthExportCore

/// 書き出した本文を見せて、渡す手段を出す画面。
/// **何を渡すのかが見えることが大事**なので、本文はそのまま出す。
struct ResultSheet: View {
    @Bindable var model: ExportModel
    @Environment(\.dismiss) private var dismiss
    @State private var fileURL: URL?
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider()
                MonospacedTextView(text: model.exportedText ?? "")
            }
            .background(Color(.systemGroupedBackground))   // 地色を指定しないとカードが同化する（4-14）
            .navigationTitle("書き出したもの")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onAppear { fileURL = model.writeTemporaryFile() }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            if let estimate = model.estimate {
                HStack(spacing: 6) {
                    Text("\(estimate.characters.formatted())文字")
                        .font(.headline).monospacedDigit()
                    Text("／ 約\(estimate.approximateTokens.formatted())トークン ／ \(estimate.lines.formatted())行")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(verdictText(estimate.verdict))
                    .font(.caption)
                    .foregroundStyle(estimate.verdict == .comfortable ? Palette.good : Palette.caution)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(estimate.verdict == .comfortable
                                ? Palette.good.opacity(0.12) : Palette.caution.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("copyButton")

                if let fileURL {
                    ShareLink(item: fileURL) {
                        Label("共有", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("shareButton")
                }
            }
            Text("AIのチャット欄に貼るなら「コピー」、ファイルとして送るなら「共有」。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func verdictText(_ verdict: SizeVerdict) -> String {
        switch verdict {
        case .comfortable:
            return "この量なら、AIのチャット欄にそのまま貼れます。"
        case .heavy:
            return "貼れますが重めです。長い会話には向きません。項目を減らすか期間を短くすると扱いやすくなります。"
        case .tooLarge:
            return "大きすぎます。多くのAIには貼れません。期間を短くするか、「1件ずつ全部」にした項目を「1日ごと」に戻してください。"
        }
    }
}
