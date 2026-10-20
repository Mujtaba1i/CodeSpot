import AppKit

/// Borderless floating panel, Spotlight style. Takes keyboard focus without activating the app.
final class Panel: NSPanel {
    private let searchView = SearchView()
    private let background: NSView
    private var flagsMonitor: Any?
    private var generation = 0 // lets a newer show() cancel a pending fade-out
    var onSettings: () -> Void = {}

    init() {
        background = Self.glass(around: searchView)
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
        contentView = background
        searchView.onClose = { [weak self] in self?.dismiss() }
        searchView.onResize = { [weak self] h in self?.fit(height: h) }
    }

    override var canBecomeKey: Bool { true }

    func toggle() { isVisible && alphaValue > 0 ? dismiss() : show() }

    /// Liquid Glass like Spotlight on macOS 26+, the older blur before that.
    private static func glass(around content: NSView) -> NSView {
        content.autoresizingMask = [.width, .height]
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            let g = NSGlassEffectView(frame: content.frame)
            g.contentView = content
            g.wantsLayer = true // for the pop-in transform
            return g
        }
        #endif
        let v = NSVisualEffectView(frame: content.frame)
        v.material = .popover
        v.blendingMode = .behindWindow
        v.state = .active
        v.wantsLayer = true
        v.layer?.cornerCurve = .continuous
        v.layer?.masksToBounds = true
        v.addSubview(content)
        return v
    }

    /// Pill while it's only the search bar, rounded panel once results show.
    private func setCornerRadius(for height: CGFloat) {
        let r = height <= SearchView.headerHeight ? SearchView.headerHeight / 2 : 24
        #if compiler(>=6.2)
        if #available(macOS 26, *), let g = background as? NSGlassEffectView { g.cornerRadius = r; return }
        #endif
        background.layer?.cornerRadius = r
    }

    /// Search bar a third of the way down the focused screen, where Spotlight sits; results grow downward. Pops in.
    func show() {
        generation += 1
        searchView.reset()
        let f = Self.focusedScreen().frame
        let h = searchView.preferredHeight
        let barTop = f.maxY - f.height * 0.29
        setFrame(NSRect(x: f.midX - frame.width / 2, y: barTop - h, width: frame.width, height: h), display: true)
        setCornerRadius(for: h)
        alphaValue = 0
        makeKeyAndOrderFront(nil)
        makeFirstResponder(searchView.field)
        searchView.mdnHeld = NSEvent.modifierFlags.contains(SearchView.mdnModifier)
        flagsMonitor = flagsMonitor ?? NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
            self?.searchView.mdnHeld = e.modifierFlags.contains(SearchView.mdnModifier)
            return e
        }

        if let layer = background.layer {
            let b = layer.bounds
            var t = CATransform3DMakeTranslation(b.midX, b.midY, 0)
            t = CATransform3DScale(t, 0.92, 0.92, 1)
            t = CATransform3DTranslate(t, -b.midX, -b.midY, 0)
            let pop = CABasicAnimation(keyPath: "transform")
            pop.fromValue = t
            pop.toValue = CATransform3DIdentity
            pop.duration = 0.2
            pop.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1.05) // slight overshoot
            layer.add(pop, forKey: "pop")
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            animator().alphaValue = 1
        }
    }

    /// Quick fade, then hide.
    func dismiss() {
        guard isVisible else { return }
        generation += 1
        let g = generation
        searchView.mdnHeld = false
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.1
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, self.generation == g else { return }
            self.orderOut(nil)
        })
    }

    /// Keeps the top edge (search field) still and animates the bottom edge.
    private func fit(height: CGFloat) {
        guard height != frame.height else { return }
        setCornerRadius(for: height)
        let target = NSRect(x: frame.minX, y: frame.maxY - height, width: frame.width, height: height)
        guard isVisible else { return setFrame(target, display: false) }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(target, display: true)
        } completionHandler: { [weak self] in
            self?.invalidateShadow()
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

    /// ⌘↩ (when ⌘ is the MDN modifier) opens MDN, ⌘, opens Settings.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return super.performKeyEquivalent(with: event) }
        switch event.charactersIgnoringModifiers {
        case "\r": searchView.activateSelected(); return true
        case ",": orderOut(nil); onSettings(); return true
        default: return super.performKeyEquivalent(with: event)
        }
    }

    override func resignKey() { super.resignKey(); dismiss() }
}
