import Combine
import SwiftUI
import HealthExportCore

struct ContentView: View {
    @Bindable var model: ExportModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingResult = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                purposeSection
                summarySection
                if model.foundNothing { emptySection }
                if let message = model.errorMessage { errorSection(message) }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ヘルスケア書き出し")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("詳しい設定", systemImage: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("settingsButton")
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

    // MARK: - 目的

    private var purposeSection: some View {
        Section {
            ForEach(Purpose.allCases, id: \.self) { purpose in
                Button {
                    Haptics.tap()
                    model.choose(purpose)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: model.settings.purpose == purpose
                              ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(model.settings.purpose == purpose ? Palette.accent : .secondary)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(purpose.title(.ja)).font(.body.weight(.semibold))
                            Text(purpose.detail(.ja)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)   // 付けないと中の文字色が青に染まる（引き継ぎ書 4-13）
                .accessibilityIdentifier("purpose-\(purpose.rawValue)")
            }
        } header: {
            Text("何のためにAIへ渡しますか")
        } footer: {
            Text("選ぶと、期間・項目・AIへの依頼文がまとめて決まります。")
        }
    }

    // MARK: - いま書き出されるもの

    private var summarySection: some View {
        Section {
            LabeledContent("期間") {
                Text("\(model.range.from.iso) 〜 \(model.range.to.iso)")
                    .monospacedDigit()
            }
            LabeledContent("日数") { Text("\(model.range.dayCount)日間") }
            LabeledContent("項目") {
                if model.phase == .scanning {
                    Text("調べています…").foregroundStyle(.secondary)
                } else {
                    Text("\(model.selectedMetrics.count)項目")
                }
            }
            if !model.selectedMetrics.isEmpty {
                Text(model.selectedMetrics.map(\.jaName).joined(separator: "、"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("書き出す内容")
        } footer: {
            Text("記録が見つからなかった項目は自動で外れます。")
        }
    }

    private var emptySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("記録が1件も見つかりませんでした").font(.body.weight(.semibold))
                // 読み取りを拒否されていても同じ見え方になる。両方の可能性を必ず書く
                Text("この期間に記録が無いか、ヘルスケアの読み取りが許可されていない可能性があります。"
                     + "「設定」アプリ →「プライバシーとセキュリティ」→「ヘルスケア」→「ヘルスケア書き出し」で、"
                     + "読み取りがオンになっているか確かめてください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("設定アプリを開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.callout)
            }
            .padding(.vertical, 4)
        }
    }

    private func errorSection(_ message: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("うまくいかなかったこと", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.caution)
                Text(message).font(.caption).foregroundStyle(.secondary)
                Button("閉じる") { model.errorMessage = nil }.font(.caption)
            }
        }
    }

    // MARK: - 書き出しボタン

    private var exportBar: some View {
        VStack(spacing: 8) {
            if case .reading(let what) = model.phase {
                HStack(spacing: 8) {
                    ProgressView()
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
                Text("書き出す")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy || model.selectedMetrics.isEmpty)
            .accessibilityIdentifier("exportButton")

            if let estimate = model.estimate, model.exportedText != nil {
                Button("前回の結果を見る（約\(estimate.characters.formatted())文字）") {
                    showingResult = true
                }
                .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.bar)
    }
}
