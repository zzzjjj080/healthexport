import SwiftUI
import HealthExportCore

/// 詳しく設定したい人のための画面。
/// 種類ごとにタブを分ける。（引き継ぎ書 8節）
/// 「形式」を触るつもりで「項目」を変えてしまう、という事故を避ける。
struct SettingsSheet: View {
    @Bindable var model: ExportModel
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .period

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

    private static let presets: [(String, Int)] = [
        ("1週間", 7), ("1ヶ月", 30), ("3ヶ月", 90), ("6ヶ月", 180), ("1年", 365)
    ]

    private var periodTab: some View {
        List {
            Section {
                ForEach(Self.presets, id: \.0) { label, days in
                    Button {
                        model.settings.customRange = nil
                        model.settings.customDays = days
                        Task { await model.rescan() }
                    } label: {
                        HStack {
                            Text(label)
                            Spacer()
                            if model.settings.customRange == nil,
                               (model.settings.customDays ?? model.settings.purpose.days) == days {
                                Image(systemName: "checkmark").foregroundStyle(Palette.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("直近")
            } footer: {
                Text("いまの期間: \(model.range.from.iso) 〜 \(model.range.to.iso)（\(model.range.dayCount)日間）")
            }

            Section("日付で指定") {
                DatePicker("はじめ", selection: fromBinding, displayedComponents: .date)
                DatePicker("おわり", selection: toBinding, displayedComponents: .date)
                if model.settings.customRange != nil {
                    Button("日付の指定をやめる") {
                        model.settings.customRange = nil
                        Task { await model.rescan() }
                    }
                }
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
                Text("この期間に記録があった項目だけを出しています。"
                     + "チェックを外すと書き出しから抜けます。")
                    .font(.caption).foregroundStyle(.secondary)
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
        }
    }
}
