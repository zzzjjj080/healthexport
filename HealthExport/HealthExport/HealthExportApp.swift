import SwiftUI

@main
struct HealthExportApp: App {
    @State private var model = ExportModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(Palette.accent)
        }
    }
}
