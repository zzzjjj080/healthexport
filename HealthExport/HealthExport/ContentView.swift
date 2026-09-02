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
    @State private var settingsTab: SettingsSheet.Tab = .period
    @State private var showingIntro = false
    @State private var askExpanded = false
    @State private var detailExpanded = false

    private let columns = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    purposeGrid
                    periodCard
                    contentCard
                    if model.foundNothing { emptyCard }
                    if !model.problems.isEmpty { errorCard(model.problems) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            // 収まっているときは弾ませない。溢れる端末・大きい文字のときだけスクロールする
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ヘルスケア書き出し")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { exportBar }
            .sheet(isPresented: $showingResult) { ResultSheet(model: model) }
            .sheet(isPresented: $showingSettings) { SettingsSheet(model: model, initialTab: settingsTab) }
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
                #if DEBUG
                await openForScreenshot()
                #endif
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

    // MARK: - 期間

    /// 期間は目的と切り離してある。押すたびに1段ずつ動く。
    private var periodCard: some View {
        HStack(spacing: 10) {
            Text("期間")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                stepButton(systemName: "minus", direction: -1, enabled: model.canStepShorter)
                VStack(spacing: 0) {
                    Text(model.periodLabel)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text(model.periodDetail)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)   // 年をまたぐと長くなる
                }
                .frame(minWidth: 104)
                stepButton(systemName: "plus", direction: 1, enabled: model.canStepLonger)
            }
            .background(Capsule().fill(Color(.tertiarySystemFill)))

            Spacer(minLength: 0)

            Button {
                settingsTab = .period
                showingSettings = true
            } label: {
                Text("日付で指定")
                    .font(.caption.weight(.medium))
                    // 文字を大きくしている人だと「日/付/で/指定」と折り返して崩れる
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: true, vertical: false)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
    }

    private func stepButton(systemName: String, direction: Int, enabled: Bool) -> some View {
        Button {
            Haptics.tap()
            Task { await model.stepPeriod(direction) }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? Palette.accent : Color(.tertiaryLabel))
                .frame(width: 42, height: 40)
                .contentShape(Rectangle())   // Spacer と同じで、これが無いと文字の上しか押せない
        }
        .buttonStyle(.plain)
        .disabled(!enabled || model.isBusy)
        .accessibilityIdentifier("period-\(systemName)")
    }

    // MARK: - 書き出されるデータ

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { detailExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("書き出されるデータ")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(model.phase == .scanning ? "調べています…" : "\(model.selectedMetrics.count)項目")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Image(systemName: detailExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !model.selectedMetrics.isEmpty {
                Divider().padding(.horizontal, 14)
                FlowLayout(spacing: 5) {
                    ForEach(shownMetrics) { metric in
                        chip(metric.jaName)
                    }
                    if !detailExpanded, hiddenMetricCount > 0 {
                        chip("ほか\(hiddenMetricCount)項目")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)

                if detailExpanded {
                    Button {
                        settingsTab = .metrics
                        showingSettings = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("項目や形式を変える")
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.accent)
                    .accessibilityIdentifier("settingsButton")
                }
            }

            Divider().padding(.horizontal, 14)
            Button {
                withAnimation(.snappy(duration: 0.2)) { askExpanded.toggle() }
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label("AIへの依頼文がつきます", systemImage: "text.bubble.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.accent)
                        Spacer()
                        Image(systemName: askExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if askExpanded {
                        Text(model.settings.purpose.askText(model.settings.options.language))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
    }

    /// たたんでいるときは頭の数個だけ見せる。全部並べると縦に伸びて、画面から溢れる。
    private var shownMetrics: [Metric] {
        detailExpanded ? model.selectedMetrics : Array(model.selectedMetrics.prefix(6))
    }
    private var hiddenMetricCount: Int {
        max(0, model.selectedMetrics.count - 6)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(.tertiarySystemFill)))
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

    private func errorCard(_ messages: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(messages.count == 1 ? "うまくいかなかったこと"
                                      : "うまくいかなかったこと（\(messages.count)件）",
                  systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.caution)
            // 1件で上書きすると、最初に起きた本当の原因が消える
            ForEach(messages, id: \.self) { message in
                Text("・" + message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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

    #if DEBUG
    /// ストア用のスクリーンショットを撮るために、目的の画面を開いた状態で起動する。
    /// シミュレータへの合成タップはシートに届かないので、こちらから開く。（引き継ぎ書 4-24）
    ///
    ///     SIMCTL_CHILD_HEALTHEXPORT_DEMO=1 SIMCTL_CHILD_HEALTHEXPORT_SHOT=result \
    ///       xcrun simctl launch booted com.zzzjjj080.HealthExport
    private func openForScreenshot() async {
        guard let shot = ProcessInfo.processInfo.environment["HEALTHEXPORT_SHOT"] else { return }
        switch shot {
        case "result":
            await model.export()
            showingResult = true
        case "detail":
            detailExpanded = true
            askExpanded = true
        case "settings":
            settingsTab = .metrics
            showingSettings = true
        case "period":
            settingsTab = .period
            showingSettings = true
        default:
            break
        }
    }
    #endif
}

/// 目的ひとつぶんのタイル。2列に並ぶので、縦に積む。
private struct PurposeTile: View {
    let purpose: Purpose
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(Palette.accentGradient)
                                         : AnyShapeStyle(Color(.tertiarySystemFill)))
                        .frame(width: 30, height: 30)
                    Image(systemName: purpose.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                }
                Spacer(minLength: 0)
                if purpose == .general {
                    Text("まずはこれ")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Palette.accentGradient))
                }
            }
            Text(purpose.title(.ja))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
            Text(purpose.detail(.ja))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(isSelected ? Palette.accent.opacity(0.9) : .clear, lineWidth: 1.6))
    }
}
