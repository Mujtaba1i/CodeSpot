import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panel = Panel()
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey!
    private let settings = SettingsWindow()
    private let defaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ note: Notification) {
        defaults.register(defaults: [
            "keyCode": kVK_Space, "modifiers": controlKey | optionKey, "shortcutLabel": "⌃⌥Space",
            "showMenuBarIcon": true,
        ])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "list.bullet.below.rectangle", accessibilityDescription: "CodeSpot")
        statusItem.isVisible = defaults.bool(forKey: "showMenuBarIcon")
        let menu = NSMenu()
        menu.addItem(withTitle: "Show CodeSpot", action: #selector(showPanel), keyEquivalent: "")
        menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "Reset Panel Position", action: #selector(resetPosition), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit CodeSpot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        panel.onSettings = { [weak self] in self?.showSettings() }
        settings.onChangeShortcut = { [weak self] in self?.changeShortcut() }
        settings.onShowMenuBarIcon = { [weak self] on in
            self?.defaults.set(on, forKey: "showMenuBarIcon")
            self?.statusItem.isVisible = on
        }

        hotKey = HotKey { [weak self] in self?.panel.toggle() }
        registerSaved()
    }

    /// Opening the app again (Finder, Spotlight, `open`) shows the panel.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.show()
        return false
    }

    @objc private func showPanel() { panel.show() }

    @objc private func resetPosition() { panel.resetPosition() }

    @objc private func showSettings() {
        settings.show(shortcutLabel: defaults.string(forKey: "shortcutLabel")!, menuBarShown: statusItem.isVisible)
    }

    @discardableResult
    private func registerSaved() -> Bool {
        return hotKey.register(keyCode: UInt32(defaults.integer(forKey: "keyCode")),
                               modifiers: UInt32(defaults.integer(forKey: "modifiers")))
    }

    /// Records the next key combo (needs ⌘, ⌃ or ⌥) and makes it the global shortcut. Esc cancels.
    private func changeShortcut() {
        hotKey.unregister() // so the current combo can be recorded again
        let alert = NSAlert()
        alert.messageText = "Press the new shortcut"
        alert.informativeText = "Use at least one of ⌘ ⌃ ⌥. Current: \(defaults.string(forKey: "shortcutLabel")!)"
        alert.addButton(withTitle: "Cancel")
        var recorded: NSEvent?
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection([.command, .control, .option])
            if event.keyCode == kVK_Escape { NSApp.stopModal(withCode: .cancel); return nil }
            guard !mods.isEmpty else { return nil }
            recorded = event
            NSApp.stopModal(withCode: .OK)
            return nil
        }
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        NSEvent.removeMonitor(monitor!)

        let old = (defaults.integer(forKey: "keyCode"), defaults.integer(forKey: "modifiers"), defaults.string(forKey: "shortcutLabel")!)
        if let e = recorded {
            defaults.set(Int(e.keyCode), forKey: "keyCode")
            defaults.set(Int(carbonModifiers(e.modifierFlags)), forKey: "modifiers")
            defaults.set(label(e), forKey: "shortcutLabel")
        }
        if !registerSaved() {
            let failed = defaults.string(forKey: "shortcutLabel")!
            defaults.set(old.0, forKey: "keyCode")
            defaults.set(old.1, forKey: "modifiers")
            defaults.set(old.2, forKey: "shortcutLabel")
            registerSaved()
            let err = NSAlert()
            err.messageText = "\(failed) is already used by another app"
            err.informativeText = "Kept \(old.2)."
            err.runModal()
        }
        showSettings()
    }
}

func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
    var m = 0
    if flags.contains(.control) { m |= controlKey }
    if flags.contains(.option) { m |= optionKey }
    if flags.contains(.shift) { m |= shiftKey }
    if flags.contains(.command) { m |= cmdKey }
    return UInt32(m)
}

/// "⌃⌥Space", "⌘⇧H", ...
private func label(_ e: NSEvent) -> String {
    let f = e.modifierFlags
    var s = ""
    if f.contains(.control) { s += "⌃" }
    if f.contains(.option) { s += "⌥" }
    if f.contains(.shift) { s += "⇧" }
    if f.contains(.command) { s += "⌘" }
    let names = [kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫"]
    return s + (names[Int(e.keyCode)] ?? (e.charactersIgnoringModifiers ?? "?").uppercased())
}
