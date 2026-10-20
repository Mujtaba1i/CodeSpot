import AppKit

/// Borderless floating panel, Spotlight style. Takes keyboard focus without activating the app.
final class Panel: NSPanel {
    private let searchView = SearchView()

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
    }

    override var canBecomeKey: Bool { true }

    func toggle() { isVisible ? orderOut(nil) : show() }

    func show() {
        searchView.reset()
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
        let f = screen.visibleFrame
        setFrameOrigin(NSPoint(x: f.midX - frame.width / 2, y: f.maxY - f.height * 0.2 - frame.height))
        makeKeyAndOrderFront(nil)
        makeFirstResponder(searchView.field)
    }

    override func resignKey() { super.resignKey(); orderOut(nil) }
}
