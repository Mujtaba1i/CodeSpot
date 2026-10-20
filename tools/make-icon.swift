// Renders the CodeSpot app icon and builds Resources/AppIcon.icns.
// Usage: swift tools/make-icon.swift   (run from the repo root)
import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(v >> 16 & 255) / 255, green: CGFloat(v >> 8 & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: a)
}
func rounded(_ size: CGFloat, _ w: NSFont.Weight) -> NSFont {
    let f = NSFont.systemFont(ofSize: size, weight: w)
    return NSFont(descriptor: f.fontDescriptor.withDesign(.rounded)!, size: size)!
}
func attr(_ s: String, _ font: NSFont, _ color: NSColor) -> NSAttributedString {
    NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
}

/// 1024 canvas, 824 squircle body per Apple's macOS icon grid. Dark panel: search pill + "200 OK".
let icon = NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { _ in
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowColor = .black.withAlphaComponent(0.3); sh.shadowBlurRadius = 20; sh.shadowOffset = NSSize(width: 0, height: -8)
    sh.set(); NSColor.black.setFill(); shape.fill()
    NSGraphicsContext.restoreGraphicsState()
    shape.addClip()
    NSGradient(colors: [hex(0x2A2D33), hex(0x0B0C0E)])!.draw(in: body, angle: -90)

    let pillY: CGFloat = 730
    let pill = NSBezierPath(roundedRect: CGRect(x: 170, y: pillY - 62, width: 684, height: 124), xRadius: 62, yRadius: 62)
    hex(0xFFFFFF, 0.12).setFill(); pill.fill()
    hex(0xFFFFFF, 0.18).setStroke(); pill.lineWidth = 3; pill.stroke()
    NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)!
        .withSymbolConfiguration(.init(pointSize: 64, weight: .semibold).applying(.init(paletteColors: [hex(0xFFFFFF, 0.8)])))!
        .draw(in: CGRect(x: 215, y: pillY - 34, width: 68, height: 68))

    // "200 OK" centered in the space under the pill.
    let code = attr("200", rounded(220, .heavy), hex(0x30D158)), ok = attr("OK", rounded(120, .bold), .white)
    let gap: CGFloat = 30, total = code.size().width + gap + ok.size().width, midY: CGFloat = 400
    let x = 512 - total / 2
    code.draw(at: CGPoint(x: x, y: midY - code.size().height / 2))
    ok.draw(at: CGPoint(x: x + code.size().width + gap, y: midY - code.size().height / 2 + (code.size().height - ok.size().height) * 0.28))
    return true
}

func png(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    icon.draw(in: CGRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let set = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: set)
try! FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
for s in [16, 32, 128, 256, 512] {
    try! png(s).write(to: set.appendingPathComponent("icon_\(s)x\(s).png"))
    try! png(s * 2).write(to: set.appendingPathComponent("icon_\(s)x\(s)@2x.png"))
}
try! png(1024).write(to: URL(fileURLWithPath: "Resources/AppIcon.png"))
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", set.path, "-o", "Resources/AppIcon.icns"]
try! p.run(); p.waitUntilExit()
print(p.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
