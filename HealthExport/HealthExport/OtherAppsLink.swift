import SwiftUI

/// 設定のいちばん下に置く「作者の他のアプリ」。
///
/// **投げ銭（コーヒー1杯）の代わりに置いた**（2026-09-30 本人判断。副業にあたるため
/// 収入の入り口を無くした）。お金は受け取らないが、置き場所と控えめな見た目は引き継ぐ。
struct OtherAppsLink: View {
    private static let url = URL(string: "https://apps.apple.com/jp/developer/jin-nakamura/id6802013586")!

    var body: some View {
        Section {
            Link(destination: Self.url) {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                    Text("作者の他のアプリ")
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .font(.footnote.weight(.medium))
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("otherApps")
        }
    }
}
