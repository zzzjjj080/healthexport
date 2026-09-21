import AppKit
import CoreGraphics
import Foundation

// 12言語ぶんのストア用画像を組む。キャプションは captions-l10n.json から読む。
//   swiftc -O MakeScreenshots-l10n.swift -o /tmp/mkshots
//   /tmp/mkshots raw-l10n screenshots-l10n captions-l10n.json
// 生の画像は raw-l10n/<言語>/01-home.png …、出力は screenshots-l10n/<言語>/。
// 言語によって文の長さがかなり違う（ドイツ語は日本語の倍近い）ので、
// 枠に収まるまで文字を縮める。

let width = 1242.0, height = 2688.0
let uiScale = width / 1242.0
let files = ["01-home.png", "02-result.png", "03-detail.png", "04-settings.png"]
let rawRoot = URL(fileURLWithPath: CommandLine.arguments[1])
let outRoot = URL(fileURLWithPath: CommandLine.arguments[2])
let captions = try! JSONDecoder().decode([String: [[String]]].self,
    from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3])))

func color(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// 日本語は元の画像と同じヒラギノ。ほかは標準の字形（中国語・韓国語・アラビア語も文字ごとに正しく選ばれる）。
func font(_ language: String, size: CGFloat, bold: Bool) -> NSFont {
    if language == "ja", let f = NSFont(name: bold ? "HiraginoSans-W7" : "HiraginoSans-W3", size: size) { return f }
    return NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
}

/// 枠に収まる大きさまで縮めて描く。
func drawFitted(_ text: String, in box: CGRect, language: String, size: CGFloat, bold: Bool, hex: UInt32) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.baseWritingDirection = language == "ar" ? .rightToLeft : .natural
    var current = size
    while true {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font(language, size: current, bold: bold),
            .foregroundColor: NSColor(cgColor: color(hex))!, .paragraphStyle: paragraph]
        // 1行ずつの幅が枠に収まっていて、全体の高さも枠に収まれば描く。
        // 行の高さで判定すると、ヒラギノのように行間の広い字形で「あふれた」と誤判定する。
        let widest = text.components(separatedBy: "\n")
            .map { ($0 as NSString).size(withAttributes: attributes).width }.max() ?? 0
        let needed = (text as NSString).boundingRect(with: CGSize(width: box.width, height: .greatestFiniteMagnitude),
                                                     options: [.usesLineFragmentOrigin], attributes: attributes)
        if (widest <= box.width && needed.height <= box.height) || current < size * 0.55 {
            (text as NSString).draw(in: box, withAttributes: attributes)
            return
        }
        current -= 2
    }
}

for (language, list) in captions.sorted(by: { $0.key < $1.key }) {
    let outDir = outRoot.appendingPathComponent(language)
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    for (index, file) in files.enumerated() {
        let shot = (file: file, title: list[index][0], subtitle: list[index][1])
        let inputDir = rawRoot.appendingPathComponent(language)
        let outputDir = outDir

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

    _ = paragraph
    let titleBox = CGRect(x: 60 * uiScale, y: height - 400 * uiScale, width: width - 120 * uiScale, height: 230 * uiScale)
    drawFitted(shot.title, in: titleBox, language: language, size: (language == "ja" ? 66 : 72) * uiScale, bold: true, hex: 0x8C0B36)
    let subtitleBox = CGRect(x: 60 * uiScale, y: height - 505 * uiScale, width: width - 120 * uiScale, height: 120 * uiScale)
    drawFitted(shot.subtitle, in: subtitleBox, language: language, size: (language == "ja" ? 36 : 40) * uiScale, bold: false, hex: 0x94526A)

    NSGraphicsContext.restoreGraphicsState()

    let output = outputDir.appendingPathComponent(shot.file)
    let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(language)/\(output.lastPathComponent)")
}
}
