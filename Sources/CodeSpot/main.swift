import AppKit

if CommandLine.arguments.contains("--selftest") {
    runSelfTest()
    exit(0)
}

// Test aid: `CodeSpot --snapshot <query> <out.png> [--mdn]` renders the results view to a PNG.
UserDefaults.standard.register(defaults: ["mdnModifier": Int(NSEvent.ModifierFlags.command.rawValue)])

if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > i + 2 {
    let view = SearchView()
    view.appearance = NSAppearance(named: .darkAqua)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor(white: 0.16, alpha: 1).cgColor // the panel's glass isn't in the snapshot
    view.reset(query: CommandLine.arguments[i + 1])
    view.setFrameSize(NSSize(width: view.frame.width, height: view.preferredHeight))
    view.mdnHeld = CommandLine.arguments.contains("--mdn")
    view.layoutSubtreeIfNeeded()
    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: rep)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 2]))
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
