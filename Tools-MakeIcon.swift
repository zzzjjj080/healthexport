import AppKit
import CoreGraphics
import Foundation

// ヘルスケア書き出しのアプリアイコン。
//
// 「ヘルスケアのデータを、外へ書き出す」を1024pxで描く。
// ホーム画面では60px程度まで縮むので、細い線や文字ではなく塊で見せる。
// Apple純正ヘルスケア（白地に赤いハート1つ）にそのまま似せるのは
// ガイドライン4.1に触れるため、必ず「書き出し」の要素と組で描く。

let S: CGFloat = 1024

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: a)
}
func newContext(_ w: Int, _ h: Int) -> CGContext {
    guard let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("context") }
    return c
}
func savePNG(_ image: CGImage, _ path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
    try! data.write(to: URL(fileURLWithPath: path))
}

/// ハート。幅 rx*2、高さ ry*2。下が尖り、上に2つの膨らみ。
func heartPath(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> CGPath {
    let p = CGMutablePath()
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: cx + x*rx, y: cy + y*ry) }
    p.move(to: P(0, -1.0))
    p.addCurve(to: P(-1.0, 0.40), control1: P(-0.34, -0.66), control2: P(-1.0, -0.02))
    p.addCurve(to: P(-0.50, 1.0), control1: P(-1.0, 0.84),   control2: P(-0.90, 1.0))
    p.addCurve(to: P(0, 0.50),    control1: P(-0.20, 1.0),   control2: P(-0.02, 0.84))
    p.addCurve(to: P(0.50, 1.0),  control1: P(0.02, 0.84),   control2: P(0.20, 1.0))
    p.addCurve(to: P(1.0, 0.40),  control1: P(0.90, 1.0),    control2: P(1.0, 0.84))
    p.addCurve(to: P(0, -1.0),    control1: P(1.0, -0.02),   control2: P(0.34, -0.66))
    p.closeSubpath()
    return p
}
/// 右向きの太い矢印。長さ len、太さ th。
func arrowPath(x: CGFloat, y: CGFloat, len: CGFloat, th: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let headW = th * 1.75, headH = th * 2.6
    p.move(to: CGPoint(x: x, y: y - th/2))
    p.addLine(to: CGPoint(x: x + len - headW, y: y - th/2))
    p.addLine(to: CGPoint(x: x + len - headW, y: y - headH/2))
    p.addLine(to: CGPoint(x: x + len, y: y))
    p.addLine(to: CGPoint(x: x + len - headW, y: y + headH/2))
    p.addLine(to: CGPoint(x: x + len - headW, y: y + th/2))
    p.addLine(to: CGPoint(x: x, y: y + th/2))
    p.closeSubpath()
    return p
}
func bar(_ ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y - h/2, width: w, height: h),
                       cornerWidth: h/2, cornerHeight: h/2, transform: nil))
    ctx.fillPath()
}
/// パスの中だけをグラデーションで塗る。
/// 純正ヘルスケアのハートは単色ではなくグラデーション。単色だと色味が違って見える。
func fillPathGradient(_ ctx: CGContext, _ path: CGPath, _ a: UInt32, _ b: UInt32) {
    let box = path.boundingBox
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                       colors: [color(a), color(b)] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.drawLinearGradient(g,
                           start: CGPoint(x: box.minX, y: box.maxY),
                           end: CGPoint(x: box.maxX, y: box.minY),
                           options: [])
    ctx.restoreGState()
}

func fillGradient(_ ctx: CGContext, _ a: UInt32, _ b: UInt32, size: CGFloat) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                       colors: [color(a), color(b)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
}

// 3案。どれも「ハート」＋「外へ出ていく」の組で描く。
func drawIcon(_ ctx: CGContext, _ variant: Int, _ size: CGFloat) {
    let k = size / S   // 1024基準で書いて縮尺だけ変える
    ctx.saveGState()
    switch variant {

    // A: 白地。左にピンクのハート、右へ流れ出す3本の記録。
    case 1:
        fillGradient(ctx, 0xFFFFFF, 0xFDECF2, size: size)
        ctx.setFillColor(color(0xE5245E))
        ctx.addPath(heartPath(cx: 355*k, cy: 512*k, rx: 240*k, ry: 225*k))
        ctx.fillPath()
        let bx = 610*k, bw = 300*k, th = 78*k
        bar(ctx, x: bx, y: 660*k, w: bw,        h: th, color(0xE5245E))
        bar(ctx, x: bx, y: 512*k, w: bw*0.72,   h: th, color(0xE5245E, 0.72))
        bar(ctx, x: bx, y: 364*k, w: bw*0.45,   h: th, color(0xE5245E, 0.45))

    // B: ピンク地。白いハートから、白い矢印が外へ出る。
    case 2:
        fillGradient(ctx, 0xFF5E7E, 0xD81B60, size: size)
        ctx.setFillColor(color(0xFFFFFF))
        ctx.addPath(heartPath(cx: 400*k, cy: 560*k, rx: 260*k, ry: 245*k))
        ctx.fillPath()
        ctx.setFillColor(color(0xFFFFFF))
        ctx.addPath(arrowPath(x: 300*k, y: 250*k, len: 430*k, th: 92*k))
        ctx.fillPath()

    // C: 白地。ピンクのハートの中に、白抜きで記録の行。
    case 3:
        fillGradient(ctx, 0xFFFFFF, 0xFDECF2, size: size)
        ctx.setFillColor(color(0xE5245E))
        ctx.addPath(heartPath(cx: 512*k, cy: 520*k, rx: 335*k, ry: 315*k))
        ctx.fillPath()
        let th = 74*k
        bar(ctx, x: 330*k, y: 660*k, w: 364*k, h: th, color(0xFFFFFF))
        bar(ctx, x: 330*k, y: 530*k, w: 270*k, h: th, color(0xFFFFFF))
        bar(ctx, x: 330*k, y: 400*k, w: 175*k, h: th, color(0xFFFFFF))

    // D: Cに「外へ出る」を足した形。中の記録が1本、ハートの外へ抜けていく。
    case 4:
        fillGradient(ctx, 0xFFFFFF, 0xFDECF2, size: size)
        ctx.setFillColor(color(0xE5245E))
        ctx.addPath(heartPath(cx: 430*k, cy: 520*k, rx: 300*k, ry: 285*k))
        ctx.fillPath()
        let t4 = 72*k
        bar(ctx, x: 300*k, y: 640*k, w: 300*k, h: t4, color(0xFFFFFF))
        bar(ctx, x: 300*k, y: 435*k, w: 200*k, h: t4, color(0xFFFFFF))
        bar(ctx, x: 300*k, y: 537*k, w: 330*k, h: t4, color(0xFFFFFF))   // 外へ抜ける1本
        ctx.setFillColor(color(0xE5245E))
        ctx.addPath(arrowPath(x: 630*k, y: 537*k, len: 260*k, th: t4))
        ctx.fillPath()

    // A2: Aを実機の大きさに耐えるようにした形。
    // ハートを大きく、線を太く、濃淡をやめて3本とも同じ濃さにする（薄い線は縮むと消える）。
    case 5:
        fillGradient(ctx, 0xFFFFFF, 0xFDECF2, size: size)
        ctx.setFillColor(color(0xE5245E))
        ctx.addPath(heartPath(cx: 335*k, cy: 512*k, rx: 278*k, ry: 262*k))
        ctx.fillPath()
        let t5 = 96*k, x5 = 648*k
        bar(ctx, x: x5, y: 650*k, w: 280*k, h: t5, color(0xE5245E))
        bar(ctx, x: x5, y: 512*k, w: 200*k, h: t5, color(0xE5245E))
        bar(ctx, x: x5, y: 374*k, w: 122*k, h: t5, color(0xE5245E))

    // A3: A2と同じ形で、地をうすいピンクにしたもの。白い壁紙でも輪郭が立つ。
    case 6:
        fillGradient(ctx, 0xFFE3EC, 0xFFB8D0, size: size)
        ctx.setFillColor(color(0xD81B60))
        ctx.addPath(heartPath(cx: 335*k, cy: 512*k, rx: 278*k, ry: 262*k))
        ctx.fillPath()
        let t6 = 96*k, x6 = 648*k
        bar(ctx, x: x6, y: 650*k, w: 280*k, h: t6, color(0xD81B60))
        bar(ctx, x: x6, y: 512*k, w: 200*k, h: t6, color(0xD81B60))
        bar(ctx, x: x6, y: 374*k, w: 122*k, h: t6, color(0xD81B60))

    // A4: A2と同じ構図で、ハートと線をグラデーションにする。
    // 色は純正ヘルスケアに寄せた明るいピンク→濃い赤。
    case 7:
        fillGradient(ctx, 0xFFFFFF, 0xFDECF2, size: size)
        let heart7 = heartPath(cx: 335*k, cy: 512*k, rx: 278*k, ry: 268*k)
        fillPathGradient(ctx, heart7, 0xFF6B8B, 0xF3054E)
        let t7 = 96*k, x7 = 648*k
        for (y, w) in [(650*k, 280*k), (512*k, 200*k), (374*k, 122*k)] {
            let bar = CGPath(roundedRect: CGRect(x: x7, y: y - t7/2, width: w, height: t7),
                             cornerWidth: t7/2, cornerHeight: t7/2, transform: nil)
            fillPathGradient(ctx, bar, 0xFF6B8B, 0xF3054E)
        }

    // A5: A4より赤に寄せたもの。純正はかなり赤い。
    case 8:
        fillGradient(ctx, 0xFFFFFF, 0xFDECF2, size: size)
        let heart8 = heartPath(cx: 335*k, cy: 512*k, rx: 278*k, ry: 268*k)
        fillPathGradient(ctx, heart8, 0xFF5A6E, 0xEB0033)
        let t8 = 96*k, x8 = 648*k
        for (y, w) in [(650*k, 280*k), (512*k, 200*k), (374*k, 122*k)] {
            let bar = CGPath(roundedRect: CGRect(x: x8, y: y - t8/2, width: w, height: t8),
                             cornerWidth: t8/2, cornerHeight: t8/2, transform: nil)
            fillPathGradient(ctx, bar, 0xFF5A6E, 0xEB0033)
        }

    default: break
    }
    ctx.restoreGState()
}

func iconImage(_ variant: Int, _ size: CGFloat) -> CGImage {
    let ctx = newContext(Int(size), Int(size))
    drawIcon(ctx, variant, size)
    return ctx.makeImage()!
}

// ---- 1024pxを3案ぶん書き出す ----
for v in [5, 7, 8] {
    savePNG(iconImage(v, S), "icon-\(["", "", "", "", "", "A2", "", "A4", "A5"][v]).png")
}

// ---- 比較シート。角丸マスクを掛けて、実際の見え方に近づける ----
let cols = [256.0, 180.0, 60.0]
let pad = 40.0, gapY = 40.0
let sheetW = Int(pad*2 + cols.reduce(0, +) + gapY*CGFloat(cols.count-1))
let sheetH = Int(pad*2 + (256+gapY)*3)
let sheet = newContext(sheetW, sheetH)
sheet.setFillColor(color(0xF2F3F7)); sheet.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))
for (row, v) in [5, 7, 8].enumerated() {
    var x = pad
    let rowTop = CGFloat(sheetH) - pad - CGFloat(row)*(256+gapY)
    for c in cols {
        let img = iconImage(v, max(c, 256))   // 縮小はCoreGraphics側に任せる
        let rect = CGRect(x: x, y: rowTop - c - (256-c)/2, width: c, height: c)
        sheet.saveGState()
        sheet.addPath(CGPath(roundedRect: rect, cornerWidth: c*0.2237, cornerHeight: c*0.2237, transform: nil))
        sheet.clip()
        sheet.draw(img, in: rect)
        sheet.restoreGState()
        x += c + gapY
    }
}
savePNG(sheet.makeImage()!, "icon-sheet.png")
print("icon-A2/A4/A5.png と icon-sheet.png")
