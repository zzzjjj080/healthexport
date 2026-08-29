import Combine
import SwiftUI
import HealthExportCore

extension Purpose {
    /// 目的ごとの記号。文字を読む前に、絵で見当がつくようにする。
    var symbolName: String {
        switch self {
        case .general:    return "square.grid.2x2.fill"
        case .sleep:      return "moon.stars.fill"
        case .training:   return "figure.run"
        case .condition:  return "waveform.path.ecg"
        case .mind:       return "brain.head.profile"
        case .everything: return "text.append"
        }
    }
}

struct ContentView: View {
    @Bindable var model: ExportModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingResult = false
    @State private var showingSettings = false
    @State private var showingIntro = false
    @State private var askExpanded = false

    private let columns = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    purposeGrid
                    contentCard
                    if model.foundNothing { emptyCard }
                    if let message = model.errorMessage { errorCard(message) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ヘルスケア書き出し")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("settingsButton")
                    .accessibilityLabel("詳しい設定")
                }
            }
            .safeAreaInset(edge: .bottom) { exportBar }
            .sheet(isPresented: $showingResult) { ResultSheet(model: model) }
            .sheet(isPresented: $showingSettings) { SettingsSheet(model: model) }
            .fullScreenCover(isPresented: $showingIntro) {
                IntroSheet {
                    model.markIntroSeen()
                    showingIntro = false
                }
            }
            // 起動時・復帰時・日をまたいだとき、の3つとも要る。（引き継ぎ書 4-18）
            .task {
                if model.needsIntro { showingIntro = true }
                await model.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await model.refresh() } }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
                .receive(on: RunLoop.main)) { _ in
                Task { await model.refresh() }
            }
        }
    }

    // MARK: - 目的

    private var purposeGrid: some View {
        LazyVGrid(columns: columns, spacing: 11) {
            ForEach(Purpose.allCases, id: \.self) { purpose in
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.22)) {
                        model.choose(purpose)
                        askExpanded = false
                    }
                } label: {
                    PurposeTile(purpose: purpose, isSelected: model.settings.purpose == purpose)
                }
                .buttonStyle(.plain)   // 付けないと中の文字色が青に染まる（引き継ぎ書 4-13）
                .accessibilityIdentifier("purpose-\(purpose.rawValue)")
            }
        }
    }

    // MARK: - このまま書き出すと

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("このまま書き出すと")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("変える") { showingSettings = true }
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
            .padding(.bottom, 10)

            HStack(spacing: 0) {
                stat("\(model.range.dayCount)", "日間",
                     "\(model.range.from.iso.dropFirst(5)) 〜 \(model.range.to.iso.dropFirst(5))")
                Rectangle().fill(Color(.separator).opacity(0.5)).frame(width: 1, height: 32)
                stat(model.phase == .scanning ? "…" : "\(model.selectedMetrics.count)", "項目",
                     model.phase == .scanning ? "調べています" : "記録があったもの")
            }
            .padding(.bottom, 12)

            if !model.selectedMetrics.isEmpty {
                Divider().padding(.horizontal, 14)
                FlowLayout(spacing: 5) {
                    ForEach(model.selectedMetrics) { metric in
                        Text(metric.jaName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                    }
                }
                .padding(14)
            }

            Divider().padding(.horizontal, 14)
            Button {
                withAnimation(.snappy(duration: 0.2)) { askExpanded.toggle() }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("AIへの依頼文がつきます", systemImage: "text.bubble.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.accent)
                        Spacer()
                        Image(systemName: askExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(model.settings.purpose.askText(model.settings.options.language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(askExpanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .buttonStyle(.plain)
        }
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
    }

    private func stat(_ value: String, _ unit: String, _ caption: String) -> some View {
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
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("うまくいかなかったこと", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.caution)
            Text(message).font(.caption).foregroundStyle(.secondary)
            Button("閉じる") { model.errorMessage = nil }.font(.caption.weight(.medium))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.bar)
    }

    private var canExport: Bool { !model.isBusy && !model.selectedMetrics.isEmpty }
}

/// 目的ひとつぶんのタイル。2列に並ぶので、縦に積む。
private struct PurposeTile: View {
    let purpose: Purpose
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(Palette.accentGradient)
                                         : AnyShapeStyle(Color(.tertiarySystemFill)))
                        .frame(width: 34, height: 34)
                    Image(systemName: purpose.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Palette.accent)
                }
            }
            if purpose == .general {
                Text("まずはこれ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Palette.accentGradient))
            }
            Text(purpose.title(.ja))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
            Text(purpose.detail(.ja))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(isSelected ? Palette.accent.opacity(0.9) : .clear, lineWidth: 1.6))
    }
}
