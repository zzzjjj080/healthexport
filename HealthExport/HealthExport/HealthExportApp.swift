import AppIntents
import SwiftUI

@main
struct HealthExportApp: App {
    @State private var model = ExportModel()

    /// **どこからも呼ばないと、ショートカットの入口の型ごとバイナリから落ちる。**
    /// 目録（Metadata.appintents）には名前が載るのに実体が無く、実行しようとすると
    /// 「アプリのショートカットを実行できません」で失敗する。ここで必ず1回触る。
    init() {
        HealthExportShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(Palette.accent)
        }
    }
}
