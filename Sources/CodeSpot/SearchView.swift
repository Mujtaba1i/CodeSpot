import AppKit

/// Search field on top, live-filtered results below. Plain AppKit (SwiftUI macros need full Xcode).
final class SearchView: NSVisualEffectView, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: () -> Void = {}
    var onResize: (CGFloat) -> Void = { _ in }
    let field = NSTextField()
    private let table = NSTableView()
    private let divider = NSBox()
    private let scroll = NSScrollView()
    private let empty = NSTextField(labelWithString: "No matching HTTP status")
    private let modeBadge = NSTextField(labelWithString: "")
    private var results: [Entry] = []

    static let headerHeight: CGFloat = 58, rowHeight: CGFloat = 50, maxRows = 8

    /// Modifier that turns ↩ into "open MDN" (Settings › Open MDN with). Defaults to ⌘.
    static var mdnModifier: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "mdnModifier")))
    }

    static func symbol(_ m: NSEvent.ModifierFlags) -> String {
        [(NSEvent.ModifierFlags.command, "⌘"), (.option, "⌥"), (.control, "⌃"), (.shift, "⇧")].first { m.contains($0.0) }?.1 ?? "⌘"
    }

    /// Just the search bar while the field is empty; grows with the results, up to maxRows.
    var preferredHeight: CGFloat {
        if field.stringValue.isEmpty { return Self.headerHeight }
        return Self.headerHeight + (results.isEmpty ? 56 : CGFloat(min(results.count, Self.maxRows)) * Self.rowHeight + 12)
    }

    /// While the MDN modifier is held, ↩ opens MDN instead of copying.
    var mdnHeld = false {
        didSet {
            guard mdnHeld != oldValue else { return }
            modeBadge.stringValue = "  MDN mode  \(Self.symbol(Self.mdnModifier))↩  "
            modeBadge.isHidden = !mdnHeld
            updateHints()
        }
    }

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 680, height: 460))
        material = .popover
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true

        let icon = NSImageView(image: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)!)
        icon.symbolConfiguration = .init(pointSize: 22, weight: .regular)
        icon.contentTintColor = .secondaryLabelColor

        field.placeholderString = "HTTP code or name — space lists all"
        field.font = .systemFont(ofSize: 26, weight: .light)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.cell?.isScrollable = true
        field.delegate = self

        divider.boxType = .separator

        table.addTableColumn(NSTableColumn(identifier: .init("row")))
        table.headerView = nil
        table.backgroundColor = .clear
        table.style = .inset
        table.rowHeight = Self.rowHeight
        table.intercellSpacing = .zero
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(activateSelected)
        table.refusesFirstResponder = true
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true

        empty.textColor = .secondaryLabelColor
        empty.isHidden = true

        modeBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        modeBadge.textColor = .white
        modeBadge.drawsBackground = true
        modeBadge.backgroundColor = .controlAccentColor
        modeBadge.wantsLayer = true
        modeBadge.layer?.cornerRadius = 5
        modeBadge.layer?.masksToBounds = true
        modeBadge.isHidden = true

        for v in [icon, field, modeBadge, divider, scroll, empty] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: topAnchor, constant: 29),
            field.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: modeBadge.leadingAnchor, constant: -8),
            field.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            modeBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            modeBadge.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor, constant: Self.headerHeight),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: divider.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            { let c = scroll.bottomAnchor.constraint(equalTo: bottomAnchor); c.priority = .defaultHigh; return c }(),
            empty.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor, constant: -4),
        ])
        reload()
    }

    required init?(coder: NSCoder) { fatalError() }

    func reset(query: String = "") {
        field.stringValue = query
        reload()
    }

    private func reload() {
        results = search(field.stringValue)
        table.reloadData()
        let barOnly = field.stringValue.isEmpty
        divider.isHidden = barOnly
        scroll.isHidden = barOnly
        empty.isHidden = barOnly || !results.isEmpty
        if !results.isEmpty { select(0) }
        onResize(preferredHeight)
    }

    private func select(_ row: Int) {
        let row = min(max(row, 0), results.count - 1)
        table.selectRowIndexes([row], byExtendingSelection: false)
        table.scrollRowToVisible(row)
    }

    /// ↩ / click: copy "404 Not Found". Modifier+↩ / modifier-click: open the MDN page in the default browser
    /// (does nothing for codes MDN doesn't cover).
    @objc func activateSelected() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow
        guard results.indices.contains(row) else { return }
        let e = results[row]
        if NSEvent.modifierFlags.contains(Self.mdnModifier) {
            guard let url = e.mdnURL else { return }
            NSWorkspace.shared.open(url)
        } else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("\(e.code) \(e.name)", forType: .string)
        }
        onClose()
    }

    private func hint(_ row: Int) -> String? {
        guard row == table.selectedRow else { return nil }
        if !mdnHeld { return "Copy ↩" }
        return results[row].mdnURL == nil ? "No MDN page for this code" : "Open MDN ↗"
    }

    private func updateHints() {
        table.enumerateAvailableRowViews { rowView, row in
            (rowView.view(atColumn: 0) as? RowView)?.setHint(hint(row), accent: mdnHeld && results[row].mdnURL != nil)
        }
    }

    // MARK: Field

    func controlTextDidChange(_ obj: Notification) { reload() }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
        switch sel {
        case #selector(moveUp(_:)): select(table.selectedRow - 1)
        case #selector(moveDown(_:)): select(table.selectedRow + 1)
        case #selector(insertNewline(_:)), #selector(insertNewlineIgnoringFieldEditor(_:)), #selector(insertLineBreak(_:)):
            activateSelected() // plain ↩, ⌥↩, ⌃↩
        case #selector(cancelOperation(_:)): onClose()
        default: return false
        }
        return true
    }

    // MARK: Table

    func numberOfRows(in tableView: NSTableView) -> Int { results.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: RowView.id, owner: nil) as? RowView ?? RowView()
        cell.show(results[row])
        cell.setHint(hint(row), accent: mdnHeld && results[row].mdnURL != nil)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) { updateHints() }
}

/// "404  Not Found" on one line (code colored by class), description smaller underneath.
private final class RowView: NSTableCellView {
    static let id = NSUserInterfaceItemIdentifier("RowView")
    private let title = NSTextField(labelWithString: "")
    private let detail = NSTextField(labelWithString: "")
    private let hint = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = Self.id
        detail.font = .systemFont(ofSize: 12)
        detail.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 12, weight: .medium)
        hint.alignment = .right
        for f in [title, detail, hint] {
            f.lineBreakMode = .byTruncatingTail
            f.translatesAutoresizingMaskIntoConstraints = false
            addSubview(f)
        }
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            title.trailingAnchor.constraint(lessThanOrEqualTo: hint.leadingAnchor, constant: -8),
            hint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            hint.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.trailingAnchor.constraint(lessThanOrEqualTo: hint.leadingAnchor, constant: -8),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(_ e: Entry) {
        let s = NSMutableAttributedString(string: String(e.code), attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .bold), .foregroundColor: e.color,
        ])
        s.append(NSAttributedString(string: "  " + e.name, attributes: [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: NSColor.labelColor,
        ]))
        title.attributedStringValue = s
        detail.stringValue = e.description
    }

    func setHint(_ text: String?, accent: Bool) {
        hint.stringValue = text ?? ""
        hint.textColor = accent ? .controlAccentColor : .tertiaryLabelColor
    }
}

extension Entry {
    var color: NSColor {
        switch code / 100 {
        case 1: .systemBlue
        case 2: .systemGreen
        case 3: .systemOrange
        case 4: .systemRed
        case 5: .systemPurple
        default: .systemGray
        }
    }
}
