import AppKit
import Carbon

/// One global hotkey via Carbon. Needs no Accessibility permission.
final class HotKey {
    private var ref: EventHotKeyRef?
    private static var onPress: () -> Void = {}

    init(onPress: @escaping () -> Void) {
        HotKey.onPress = onPress
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKey.onPress()
            return noErr
        }, 1, &spec, nil, nil)
    }

    /// keyCode is a virtual key code (kVK_*), modifiers are Carbon flags (controlKey, optionKey, ...).
    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        unregister()
        return RegisterEventHotKey(keyCode, modifiers, EventHotKeyID(signature: 0x4353_5054, id: 1),
                                   GetApplicationEventTarget(), 0, &ref) == noErr
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
    }
}

/// macOS's own shortcuts (System Settings › Keyboard › Keyboard Shortcuts) win over any app's hotkey,
/// and RegisterEventHotKey doesn't report the clash. Returns the macOS action using this combo, if any.
func macOSShortcut(keyCode: Int, flags: NSEvent.ModifierFlags,
                   table: [String: Any]? = UserDefaults(suiteName: "com.apple.symbolichotkeys")?
                       .dictionary(forKey: "AppleSymbolicHotKeys")) -> String? {
    let mask: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
    let names = ["60": "Select the previous input source", "61": "Select next source in Input menu",
                 "64": "Show Spotlight search", "65": "Show Finder search window",
                 "32": "Mission Control", "33": "Application windows", "36": "Show Desktop",
                 "79": "Move left a space", "81": "Move right a space"]
    for (id, entry) in table ?? [:] {
        guard let e = entry as? [String: Any], e["enabled"] as? Bool == true,
              let p = (e["value"] as? [String: Any])?["parameters"] as? [Int], p.count == 3 else { continue }
        if p[1] == keyCode && NSEvent.ModifierFlags(rawValue: UInt(p[2])).intersection(mask) == flags.intersection(mask) {
            return names[id] ?? "a macOS keyboard shortcut"
        }
    }
    // Newer macOS keeps Spotlight's shortcut out of that table, so check its default directly.
    if keyCode == 49 && flags.intersection(mask) == .command && table?["64"] == nil { return "Show Spotlight search" }
    return nil
}

func hotKeySelfTest() {
    let table: [String: Any] = [
        "61": ["enabled": true, "value": ["parameters": [32, 49, 0x40000 | 0x80000]]], // ⌃⌥Space
        "60": ["enabled": false, "value": ["parameters": [32, 49, 0x40000]]],          // ⌃Space, off
    ]
    precondition(macOSShortcut(keyCode: 49, flags: [.control, .option], table: table) == "Select next source in Input menu",
                 "⌃⌥Space should clash with the input-source shortcut")
    precondition(macOSShortcut(keyCode: 49, flags: [.control], table: table) == nil, "disabled shortcuts don't clash")
    precondition(macOSShortcut(keyCode: 49, flags: [.option], table: table) == nil, "⌥Space is free here")
    precondition(macOSShortcut(keyCode: 49, flags: [.control, .option, .capsLock], table: table) != nil, "caps lock is ignored")
    precondition(macOSShortcut(keyCode: 49, flags: [.command], table: table) == "Show Spotlight search", "⌘Space is Spotlight")
    print("selftest: macOS shortcut clash check OK")
}
