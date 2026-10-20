import AppKit

/// Borderless floating panel, Spotlight style. Takes keyboard focus without activating the app.
final class Panel: NSPanel {
    private let searchView = SearchView()
    private let background: NSView
    private var flagsMonitor: Any?
    private var generation = 0 // lets a newer show() cancel a pending fade-out
    private var restingFrame = NSRect.zero // where the panel settles; the open bounce wobbles around it
    private var bounce: Timer?
    private static let width = SearchView.width
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

    /// Liquid Glass like Spotlight on macOS 26+, plus a faint frost for a little extra blur;
    /// the older blur before that.
    private static func glass(around content: NSView) -> NSView {
        content.autoresizingMask = [.width, .height]
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            let frost = NSVisualEffectView(frame: content.frame)
            frost.material = .hudWindow
            frost.blendingMode = .behindWindow
            frost.state = .active
            frost.alphaValue = 0.35 // shortcut: tune here; higher = blurrier/darker
            frost.autoresizingMask = [.width, .height]
            let stack = NSView(frame: content.frame) // frost and content as siblings so the text isn't faded
            stack.wantsLayer = true
            stack.layer?.masksToBounds = true
            stack.layer?.cornerCurve = .continuous
            stack.addSubview(frost)
            stack.addSubview(content)
            let g = NSGlassEffectView(frame: content.frame)
            g.contentView = stack
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
        if #available(macOS 26, *), let g = background as? NSGlassEffectView {
            g.cornerRadius = r
            g.contentView?.layer?.cornerRadius = r
            return
        }
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
        restingFrame = NSRect(x: f.midX - Self.width / 2, y: barTop - h, width: Self.width, height: h)
        setCornerRadius(for: h)
        alphaValue = 0
        makeKeyAndOrderFront(nil)
        makeFirstResponder(searchView.field)
        searchView.mdnHeld = NSEvent.modifierFlags.contains(SearchView.mdnModifier)
        flagsMonitor = flagsMonitor ?? NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
            self?.searchView.mdnHeld = e.modifierFlags.contains(SearchView.mdnModifier)
            return e
        }

        startBounce()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            animator().alphaValue = 1
        }
    }

    /// Spotlight-style open: starts stretched (mostly wider), springs back to size with a small bounce.
    private func startBounce() {
        bounce?.invalidate()
        let start = CACurrentMediaTime()
        func step() {
            let t = CACurrentMediaTime() - start
            // Damped oscillation: +12% wide at t=0, ~3% too narrow at 0.17 s, settled by 0.5 s.
            let k = t >= 0.5 ? 0 : exp(-t / 0.12) * cos(2 * .pi * 3 * t)
            let r = restingFrame
            let w = r.width * (1 + 0.12 * k), h = r.height * (1 + 0.08 * k)
            setFrame(NSRect(x: r.midX - w / 2, y: r.midY - h / 2, width: w, height: h), display: true)
            if k == 0 { bounce?.invalidate(); bounce = nil; invalidateShadow() }
        }
        step()
        bounce = Timer(timeInterval: 1.0 / 120, repeats: true) { _ in step() }
        RunLoop.main.add(bounce!, forMode: .common)
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
        guard height != restingFrame.height else { return }
        setCornerRadius(for: height)
        restingFrame = NSRect(x: restingFrame.minX, y: restingFrame.maxY - height, width: restingFrame.width, height: height)
        let target = restingFrame
        guard isVisible, bounce == nil else { return } // the bounce settles on restingFrame itself
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
