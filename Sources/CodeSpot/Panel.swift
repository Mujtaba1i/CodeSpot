import AppKit

/// Borderless floating panel, Spotlight style. Takes keyboard focus without activating the app.
final class Panel: NSPanel {
    private let searchView = SearchView()
    private var flagsMonitor: Any?
    var onSettings: () -> Void = {}

    init() {
        super.init(contentRect: searchView.frame,
                   styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                   backing: .buffered, defer: false)
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = searchView
        searchView.onClose = { [weak self] in self?.orderOut(nil) }
        searchView.onResize = { [weak self] h in self?.fit(height: h) }
    }

    override var canBecomeKey: Bool { true }

    func toggle() { isVisible ? orderOut(nil) : show() }

    func show() {
        searchView.reset()
        let f = Self.focusedScreen().visibleFrame
        setFrame(NSRect(x: f.midX - frame.width / 2, y: f.maxY - f.height * 0.2 - searchView.preferredHeight,
                        width: frame.width, height: searchView.preferredHeight), display: true)
        makeKeyAndOrderFront(nil)
        makeFirstResponder(searchView.field)
        searchView.commandHeld = NSEvent.modifierFlags.contains(.command)
        flagsMonitor = flagsMonitor ?? NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
            self?.searchView.commandHeld = e.modifierFlags.contains(.command)
            return e
        }
    }

    /// Keeps the top edge (search field) still and animates the bottom edge.
    private func fit(height: CGFloat) {
        guard height != frame.height else { return }
        let target = NSRect(x: frame.minX, y: frame.maxY - height, width: frame.width, height: height)
        guard isVisible else { return setFrame(target, display: false) }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(target, display: true)
        }
    }

    /// Screen holding the frontmost app's front window; falls back to the screen under the mouse.
    private static func focusedScreen() -> NSScreen {
        let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        if let w = windows.first(where: { $0[kCGWindowOwnerPID as String] as? pid_t == pid && $0[kCGWindowLayer as String] as? Int == 0 }),
           let bounds = w[kCGWindowBounds as String] as? NSDictionary,
           let r = CGRect(dictionaryRepresentation: bounds) {
            // Window list uses top-left origin on the primary screen; AppKit uses bottom-left.
            let center = CGPoint(x: r.midX, y: NSScreen.screens[0].frame.maxY - r.midY)
            if let s = NSScreen.screens.first(where: { $0.frame.contains(center) }) { return s }
        }
        return NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
    }

    /// ⌘↩ opens MDN, ⌘, opens Settings.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return super.performKeyEquivalent(with: event) }
        switch event.charactersIgnoringModifiers {
        case "\r": searchView.activateSelected(); return true
        case ",": orderOut(nil); onSettings(); return true
        default: return super.performKeyEquivalent(with: event)
        }
    }

    override func orderOut(_ sender: Any?) {
        super.orderOut(sender)
        searchView.commandHeld = false
    }

    override func resignKey() { super.resignKey(); orderOut(nil) }
}
