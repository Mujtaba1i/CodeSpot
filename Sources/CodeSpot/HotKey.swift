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
