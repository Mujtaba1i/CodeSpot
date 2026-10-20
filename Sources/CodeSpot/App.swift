import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panel = Panel()
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey!

    func applicationDidFinishLaunching(_ note: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "number.square", accessibilityDescription: "CodeSpot")
        let menu = NSMenu()
        menu.addItem(withTitle: "Show CodeSpot", action: #selector(showPanel), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit CodeSpot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        hotKey = HotKey { [weak self] in self?.panel.toggle() }
        hotKey.register(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey))
    }

    /// Opening the app again (Finder, Spotlight, `open`) shows the panel.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.show()
        return false
    }

    @objc private func showPanel() { panel.show() }
}
