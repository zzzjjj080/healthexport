import AppKit
import CoreGraphics
import Foundation

// App Store用のスクリーンショットを組む使い捨てスクリプト。
// 生のスクリーンショットの上にキャプションを載せ、App Store の枠に合わせた大きさに収める。

// 既定はApp Store の枠に合わせた大きさ。第3・第4引数で他のサイズにも出せる
let width = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3])! : 1242.0
let height = CommandLine.arguments.count > 4 ? Double(CommandLine.arguments[4])! : 2688.0
let uiScale = width / 1242.0

struct Shot {
    let file: String
    let title: String
    let subtitle: String
}

let shots = [
    Shot(file: "01-home.png",     title: "ヘルスケアの記録を、\nAIに渡せる文章に",
         subtitle: "目的を選ぶだけ。期間も項目も、依頼文も決まります"),
    Shot(file: "02-result.png",   title: "1枚のテキストに\nまとまる",
         subtitle: "そのままチャット欄に貼れる量かどうかも分かります"),
    Shot(file: "03-detail.png",   title: "何が渡るのか、\n先に見える",
         subtitle: "記録がある項目だけを自動で選びます"),
    Shot(file: "04-settings.png", title: "細かく決めることも\nできる",
         subtitle: "項目もまとめ方も、あとから変えられます"),
]

let inputDir = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDir = URL(fileURLWithPath: CommandLine.arguments[2])
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

for shot in shots {
    guard let context = CGContext(
        data: nil, width: Int(width), height: Int(height),
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("context") }

    // 背景。アプリアイコンの紺に合わせる
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [color(0xFFF3F7), color(0xFFD3E1)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: height),
        end: CGPoint(x: 0, y: 0),
        options: []
    )

    // 端末画面。角丸にして影を落とす
    let source = NSImage(contentsOf: inputDir.appendingPathComponent(shot.file))!
    var rect = CGRect(x: 0, y: 0, width: source.size.width, height: source.size.height)
    let cgSource = source.cgImage(forProposedRect: &rect, context: nil, hints: nil)!

    let shotWidth = width * 0.76
    let shotHeight = shotWidth * (height / width)
    let shotRect = CGRect(
        x: (width - shotWidth) / 2,
        y: -shotHeight * 0.02,
        width: shotWidth,
        height: shotHeight
    )
    let clip = CGPath(roundedRect: shotRect, cornerWidth: 56 * uiScale, cornerHeight: 56 * uiScale, transform: nil)

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -18),
        blur: 46,
        color: CGColor(red: 0.45, green: 0.06, blue: 0.18, alpha: 0.22)
    )
    context.addPath(clip)
    context.setFillColor(color(0xFFFFFF))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(clip)
    context.clip()
    context.draw(cgSource, in: shotRect)
    context.restoreGState()

    // キャプション
    let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsContext

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let title = shot.title as NSString
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "HiraginoSans-W7", size: 74 * uiScale) ?? NSFont.systemFont(ofSize: 84 * uiScale, weight: .bold),
        .foregroundColor: NSColor(cgColor: color(0x8C0B36))!,
        .paragraphStyle: paragraph,
    ]
    let titleBox = CGRect(x: 60 * uiScale, y: height - 400 * uiScale, width: width - 120 * uiScale, height: 230 * uiScale)
    title.draw(in: titleBox, withAttributes: titleAttributes)

    let subtitle = shot.subtitle as NSString
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "HiraginoSans-W3", size: 40 * uiScale) ?? NSFont.systemFont(ofSize: 44 * uiScale),
        .foregroundColor: NSColor(cgColor: color(0x94526A))!,
        .paragraphStyle: paragraph,
    ]
    let subtitleBox = CGRect(x: 60 * uiScale, y: height - 505 * uiScale, width: width - 120 * uiScale, height: 120 * uiScale)
    subtitle.draw(in: subtitleBox, withAttributes: subtitleAttributes)

    NSGraphicsContext.restoreGraphicsState()

    let output = outputDir.appendingPathComponent(shot.file)
    let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(output.lastPathComponent)")
}
