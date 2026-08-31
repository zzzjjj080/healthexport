import SwiftUI
import HealthExportCore

/// 詳しく設定したい人のための画面。
/// 種類ごとにタブを分ける。（引き継ぎ書 8節）
/// 「形式」を触るつもりで「項目」を変えてしまう、という事故を避ける。
struct SettingsSheet: View {
    @Bindable var model: ExportModel
    var initialTab: Tab = .period
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .period
    @State private var tipJar = TipJar(productID: TipJar.productID)

    enum Tab: String, CaseIterable {
        case period = "期間"
        case metrics = "項目"
        case format = "形式"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                switch tab {
                case .period:  periodTab
                case .metrics: metricsTab
                case .format:  formatTab
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { tab = initialTab }
            .navigationTitle("詳しい設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("完了") { dismiss() } }
                ToolbarItem(placement: .topBarLeading) {
                    Button("目的にまかせる") {
                        model.choose(model.settings.purpose)
                        Task { await model.rescan() }
                    }
                    .font(.callout)
                }
            }
        }
    }

    // MARK: - 期間

    private var presets: [Int] { PeriodChoice.steps }

    private func isPresetActive(_ days: Int) -> Bool {
        model.settings.customRange == nil && model.currentDays == days
    }

    private var periodTab: some View {
        List {
            Section {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(presets, id: \.self) { days in
                        let active = isPresetActive(days)
                        Button {
                            Haptics.tap()
                            model.settings.customRange = nil
                            model.settings.customDays = days
                            Task { await model.rescan() }
                        } label: {
                            Text(PeriodChoice.label(days, .ja))
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(active ? Color.white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(active ? AnyShapeStyle(Palette.accentGradient)
                                                 : AnyShapeStyle(Color(.tertiarySystemFill))))
                                // Spacer は描画を持たないので、これが無いと文字の上しか押せない
                                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("period-\(days)")
                    }
                }
                .padding(.vertical, 4)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("直近")
            } footer: {
                Text("いまの期間: \(model.range.from.iso) 〜 \(model.range.to.iso)（\(model.range.dayCount)日間）")
            }

            Section {
                DatePicker("はじめ", selection: fromBinding, in: ...Date(), displayedComponents: .date)
                DatePicker("おわり", selection: toBinding, in: ...Date(), displayedComponents: .date)
                if model.settings.customRange != nil {
                    Button("日付の指定をやめる") {
                        model.settings.customRange = nil
                        Task { await model.rescan() }
                    }
                }
            } header: {
                Text("日付で指定")
            } footer: {
                Text("日付を選ぶと、上の「直近」より優先されます。")
            }
        }
    }

    private var fromBinding: Binding<Date> {
        Binding(
            get: { model.range.from.date() ?? Date() },
            set: { newValue in
                let to = model.range.to
                model.settings.customRange = DateRange(from: YMD.from(newValue), to: to)
                Task { await model.rescan() }
            })
    }

    private var toBinding: Binding<Date> {
        Binding(
            get: { model.range.to.date() ?? Date() },
            set: { newValue in
                let from = model.range.from
                model.settings.customRange = DateRange(from: from, to: YMD.from(newValue))
                Task { await model.rescan() }
            })
    }

    // MARK: - 項目

    private var metricsTab: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("この期間に記録があった項目だけを出しています。"
                         + "チェックを外すと書き出しから抜けます。")
                        .font(.caption).foregroundStyle(.secondary)
                    Button {
                        Haptics.tap()
                        Task { await model.requestAuthorizationAgain() }
                    } label: {
                        Label("ヘルスケアの許可をもう一度求める", systemImage: "heart.text.square")
                            .font(.callout.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("reauthorizeButton")
                    // 一度断った項目は、アプリから呼んでもダイアログが出ない。逃げ道を必ず用意する
                    Text("最初に「許可しない」を選んだ場合、この操作では画面が出ないことがあります。"
                         + "そのときは設定アプリから変えてください。")
                        .font(.caption2).foregroundStyle(.secondary)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("設定アプリを開く", systemImage: "gear")
                            .font(.callout.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.vertical, 2)
            }

            ForEach(MetricCategory.allCases, id: \.self) { category in
                let metrics = MetricCatalog.all.filter {
                    $0.category == category && (model.availability[$0.id]?.hasData ?? false)
                }
                if !metrics.isEmpty {
                    Section(category.name(.ja)) {
                        ForEach(metrics) { metric in
                            metricRow(metric)
                        }
                    }
                }
            }

            let missing = MetricCatalog.all.filter { !(model.availability[$0.id]?.hasData ?? false) }
            if !missing.isEmpty {
                Section {
                    Text(missing.map(\.jaName).joined(separator: "、"))
                        .font(.caption).foregroundStyle(.secondary)
                } header: {
                    Text("この期間に記録が無かった項目")
                } footer: {
                    Text("持っている端末で測れないもののほか、ヘルスケアの読み取りが許可されていない場合もここに入ります。")
                }
            }
        }
    }

    private func metricRow(_ metric: Metric) -> some View {
        let selected = model.selectedMetrics.contains { $0.id == metric.id }
        let availability = model.availability[metric.id]
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                Haptics.tap()
                toggle(metric)
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: selected ? "checkmark.square.fill" : "square")
                        .foregroundStyle(selected ? Palette.accent : .secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(metric.jaName)
                        if let names = availability?.sourceNames, !names.isEmpty {
                            Text(names.joined(separator: " / "))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())   // これが無いと文字の上しか押せない
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("metric-\(metric.id.rawValue)")

            if selected, metric.supportsRawSamples, let availability {
                Picker("まとめ方", selection: granularityBinding(metric)) {
                    Text("1日ごとにまとめる（おすすめ）").tag(false)
                    Text("記録を1件ずつ全部（およそ\(availability.estimatedSamples.formatted())件）").tag(true)
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
        }
    }

    private func toggle(_ metric: Metric) {
        var current = model.selectedMetrics.map(\.id)
        if let index = current.firstIndex(of: metric.id) {
            current.remove(at: index)
        } else {
            current.append(metric.id)
        }
        model.settings.customMetrics = current
    }

    private func granularityBinding(_ metric: Metric) -> Binding<Bool> {
        Binding(
            get: { model.settings.options.rawMetrics.contains(metric.id) },
            set: { isRaw in
                if isRaw { model.settings.options.rawMetrics.insert(metric.id) }
                else { model.settings.options.rawMetrics.remove(metric.id) }
            })
    }

    // MARK: - 形式

    private var formatTab: some View {
        List {
            Section("書き出す言語") {
                Picker("言語", selection: $model.settings.options.language) {
                    Text("日本語").tag(Language.ja)
                    Text("English").tag(Language.en)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("AIへの依頼文を付ける", isOn: $model.settings.options.includeAsk)
                if model.settings.options.includeAsk {
                    Text(model.settings.purpose.askText(model.settings.options.language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("依頼文")
            } footer: {
                Text("目的を変えると内容も変わります。")
            }

            Section {
                Toggle("端末の名前を入れる", isOn: $model.settings.options.includeDeviceNames)
            } footer: {
                Text("ヘルスケアの端末名は「〇〇のApple Watch」のように、名前が入っていることがあります。"
                     + "渡す相手によっては外してください。")
            }

            Section("表のかたち") {
                Picker("並べ方", selection: $model.settings.options.layout) {
                    Text("日付でそろえた1枚の表").tag(Layout.wide)
                    Text("項目ごとに分ける").tag(Layout.block)
                }
                Picker("列の区切り", selection: $model.settings.options.separator) {
                    Text("タブ").tag(Separator.tab)
                    Text("カンマ").tag(Separator.comma)
                    Text("見やすく揃える").tag(Separator.aligned)
                }
                Toggle("列名を英字の略称にする", isOn: $model.settings.options.shortColumnNames)
            }

            Section {
                Picker("先頭の説明文", selection: $model.settings.options.header) {
                    Text("くわしく").tag(HeaderDetail.full)
                    Text("最小限").tag(HeaderDetail.minimal)
                    Text("なし").tag(HeaderDetail.none)
                }
                Toggle("記録が無い日は行ごと省く", isOn: $model.settings.options.skipEmptyDays)
            } footer: {
                Text("説明文には「値は重複を除いたあとの数字」「空欄は記録が無いという意味で、0ではない」という断りが入ります。"
                     + "AIの読み違いを防ぐためのものなので、残しておくのがおすすめです。")
            }

            CoffeeTipSection(tipJar: tipJar)
        }
    }
}
