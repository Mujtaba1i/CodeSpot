import AppKit
import ServiceManagement

/// Shortcut, launch at login, menu bar icon.
final class SettingsWindow: NSWindow {
    var onChangeShortcut: () -> Void = {}
    var onShowMenuBarIcon: (Bool) -> Void = { _ in }
    private let shortcut = NSButton(title: "", target: nil, action: nil)
    private let login = NSButton(checkboxWithTitle: "Launch CodeSpot at login", target: nil, action: nil)
    private let menuBar = NSButton(checkboxWithTitle: "Show icon in menu bar", target: nil, action: nil)

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 400, height: 180), styleMask: [.titled, .closable],
                   backing: .buffered, defer: false)
        title = "CodeSpot Settings"
        isReleasedWhenClosed = false
        for (b, sel) in [(shortcut, #selector(changeShortcut)), (login, #selector(toggleLogin)), (menuBar, #selector(toggleMenuBar))] {
            b.target = self
            b.action = sel
        }
        let note = NSTextField(wrappingLabelWithString: "When the icon is hidden, press ⌘, in the search panel to open Settings.")
        note.font = .systemFont(ofSize: 11)
        note.textColor = .secondaryLabelColor
        note.preferredMaxLayoutWidth = 260
        let grid = NSGridView(views: [
            [NSTextField(labelWithString: "Shortcut:"), shortcut],
            [NSGridCell.emptyContentView, login],
            [NSGridCell.emptyContentView, menuBar],
            [NSGridCell.emptyContentView, note],
        ])
        grid.rowSpacing = 10
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.translatesAutoresizingMaskIntoConstraints = false
        contentView!.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: contentView!.centerXAnchor),
            grid.topAnchor.constraint(equalTo: contentView!.topAnchor, constant: 22),
            grid.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor, constant: -22),
        ])
    }

    func show(shortcutLabel: String, menuBarShown: Bool) {
        shortcut.title = shortcutLabel
        menuBar.state = menuBarShown ? .on : .off
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        center()
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    @objc private func changeShortcut() { onChangeShortcut() }

    @objc private func toggleMenuBar() { onShowMenuBarIcon(menuBar.state == .on) }

    @objc private func toggleLogin() {
        do {
            if login.state == .on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSAlert(error: error).runModal()
        }
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}
