import Combine
import SwiftUI
import HealthExportCore

extension Purpose {
    /// 目的ごとの記号。文字を読む前に、絵で見当がつくようにする。
    var symbolName: String {
        switch self {
        case .general:    return "chart.line.uptrend.xyaxis"
        case .sleep:      return "moon.stars.fill"
        case .training:   return "figure.run"
        case .condition:  return "waveform.path.ecg"
        case .everything: return "text.append"
        }
    }
}

struct ContentView: View {
    @Bindable var model: ExportModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingResult = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    hero
                    purposeList
                    summaryCard
                    if model.foundNothing { emptyCard }
                    if let message = model.errorMessage { errorCard(message) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ヘルスケア書き出し")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("settingsButton")
                    .accessibilityLabel("詳しい設定")
                }
            }
            .safeAreaInset(edge: .bottom) { exportBar }
            .sheet(isPresented: $showingResult) { ResultSheet(model: model) }
            .sheet(isPresented: $showingSettings) { SettingsSheet(model: model) }
            // 起動時・復帰時・日をまたいだとき、の3つとも要る。（引き継ぎ書 4-18）
            .task { await model.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await model.refresh() } }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
                .receive(on: RunLoop.main)) { _ in
                Task { await model.refresh() }
            }
        }
    }

    // MARK: - 見出し

    private var hero: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ヘルスケアの記録を、\nAIに渡せる文章に。")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .lineSpacing(2)
            Text("期間も項目も、目的を選べば決まります。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    // MARK: - 目的

    private var purposeList: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("何のためにAIへ渡しますか")
            ForEach(Purpose.allCases, id: \.self) { purpose in
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.2)) { model.choose(purpose) }
                } label: {
                    PurposeCard(purpose: purpose, isSelected: model.settings.purpose == purpose)
                }
                .buttonStyle(.plain)   // 付けないと中の文字色が青に染まる（引き継ぎ書 4-13）
                .accessibilityIdentifier("purpose-\(purpose.rawValue)")
            }
        }
    }

    // MARK: - 書き出す内容

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("書き出す内容")
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    stat(value: "\(model.range.dayCount)", unit: "日間", caption: "期間")
                    divider
                    stat(value: model.phase == .scanning ? "…" : "\(model.selectedMetrics.count)",
                         unit: "項目", caption: "書き出す")
                    divider
                    stat(value: "\(model.range.from.iso.dropFirst(5))",
                         unit: "から", caption: model.range.to.iso.dropFirst(5) + " まで")
                }
                .padding(.vertical, 16)

                if !model.selectedMetrics.isEmpty {
                    Divider().padding(.horizontal, 16)
                    Text(model.selectedMetrics.map(\.jaName).joined(separator: "、"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
            .background(cardBackground)
            Text("記録が見つからなかった項目は自動で外れます。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
        }
    }

    private var divider: some View {
        Rectangle().fill(Color(.separator).opacity(0.5)).frame(width: 1, height: 34)
    }

    private func stat(value: some StringProtocol, unit: String, caption: some StringProtocol) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text(unit).font(.caption2).foregroundStyle(.secondary)
            }
            Text(caption).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - 記録が無いとき

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("記録が1件も見つかりませんでした", systemImage: "questionmark.folder")
                .font(.subheadline.weight(.semibold))
            // 読み取りを拒否されていても同じ見え方になる。両方の可能性を必ず書く
            Text("この期間に記録が無いか、ヘルスケアの読み取りが許可されていない可能性があります。"
                 + "「設定」→「プライバシーとセキュリティ」→「ヘルスケア」→「ヘルスケア書き出し」で、"
                 + "読み取りがオンになっているか確かめてください。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("設定アプリを開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.callout.weight(.medium))
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("うまくいかなかったこと", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.caution)
            Text(message).font(.caption).foregroundStyle(.secondary)
            Button("閉じる") { model.errorMessage = nil }
                .font(.caption.weight(.medium))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.caution.opacity(0.10)))
    }

    // MARK: - 書き出しボタン

    private var exportBar: some View {
        VStack(spacing: 10) {
            if case .reading(let what) = model.phase {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(what).font(.caption).foregroundStyle(.secondary)
                }
            }
            Button {
                Haptics.tap()
                Task {
                    await model.export()
                    if model.exportedText != nil {
                        Haptics.finished()
                        showingResult = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.on.square.fill")
                    Text("書き出す")
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Palette.accentGradient)
                        .opacity(canExport ? 1 : 0.35))
            }
            .buttonStyle(.plain)
            .disabled(!canExport)
            .accessibilityIdentifier("exportButton")

            if model.exportedText != nil, let estimate = model.estimate {
                Button("前回の結果を見る（\(estimate.characters.formatted())文字）") {
                    showingResult = true
                }
                .font(.caption)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.bar)
    }

    private var canExport: Bool { !model.isBusy && !model.selectedMetrics.isEmpty }
}

/// 目的ひとつぶんのカード。
private struct PurposeCard: View {
    let purpose: Purpose
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Palette.accentGradient)
                                     : AnyShapeStyle(Color(.tertiarySystemFill)))
                    .frame(width: 46, height: 46)
                Image(systemName: purpose.symbolName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(purpose.title(.ja))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(purpose.detail(.ja))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Palette.accent : Color(.tertiaryLabel))
                .font(.title3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? Palette.accent.opacity(0.9) : .clear, lineWidth: 1.6))
        .shadow(color: .black.opacity(isSelected ? 0.06 : 0.03), radius: isSelected ? 8 : 3, y: 2)
    }
}
