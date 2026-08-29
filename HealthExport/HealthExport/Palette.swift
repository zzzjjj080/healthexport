import SwiftUI
import UIKit

/// 色は明暗のペアで1か所に持つ。（引き継ぎ書 4-30）
/// 色ごとに if を書くと必ず破綻する。
enum Palette {
    private static func dynamic(dark: UInt32, light: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }

    /// アイコンと同じピンク。
    static let accent = dynamic(dark: 0xFF6392, light: 0xE5245E)
    static let accentSoft = dynamic(dark: 0x2A1620, light: 0xFDECF2)
    static let caution = dynamic(dark: 0xFFB27A, light: 0xC2410C)
    static let good = dynamic(dark: 0x6EE7B7, light: 0x1E9E6A)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

/// 触覚。使い回して prepare しておかないと1打目が鳴らない。（引き継ぎ書 4-29）
@MainActor
enum Haptics {
    private static let impact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notice = UINotificationFeedbackGenerator()

    static func tap() {
        impact.prepare()
        impact.impactOccurred(intensity: 1.0)
    }

    static func finished() {
        notice.prepare()
        notice.notificationOccurred(.success)
    }
}
