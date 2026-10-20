import AppKit

/// Search field on top, live-filtered results below. Plain AppKit (SwiftUI macros need full Xcode).
final class SearchView: NSVisualEffectView, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: () -> Void = {}
    let field = NSTextField()
    private let table = NSTableView()
    private let empty = NSTextField(labelWithString: "No matching HTTP status")
    private var results = httpCodes

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

        field.placeholderString = "HTTP status code or name"
        field.font = .systemFont(ofSize: 26, weight: .light)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.cell?.isScrollable = true
        field.delegate = self

        let divider = NSBox()
        divider.boxType = .separator

        table.addTableColumn(NSTableColumn(identifier: .init("row")))
        table.headerView = nil
        table.backgroundColor = .clear
        table.style = .inset
        table.rowHeight = 50
        table.intercellSpacing = .zero
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(copySelected)
        table.refusesFirstResponder = true
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true

        empty.textColor = .secondaryLabelColor
        empty.isHidden = true

        for v in [icon, field, divider, scroll, empty] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: topAnchor, constant: 29),
            field.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            field.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor, constant: 58),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: divider.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            empty.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor),
        ])
        reload()
    }

    required init?(coder: NSCoder) { fatalError() }

    func reset() {
        field.stringValue = ""
        reload()
    }

    private func reload() {
        results = search(field.stringValue)
        table.reloadData()
        empty.isHidden = !results.isEmpty
        if !results.isEmpty { select(0) }
    }

    private func select(_ row: Int) {
        let row = min(max(row, 0), results.count - 1)
        table.selectRowIndexes([row], byExtendingSelection: false)
        table.scrollRowToVisible(row)
    }

    /// Enter / click: copy "404 Not Found" and close.
    @objc private func copySelected() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow
        guard results.indices.contains(row) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(results[row].code) \(results[row].name)", forType: .string)
        onClose()
    }

    // MARK: Field

    func controlTextDidChange(_ obj: Notification) { reload() }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
        switch sel {
        case #selector(moveUp(_:)): select(table.selectedRow - 1)
        case #selector(moveDown(_:)): select(table.selectedRow + 1)
        case #selector(insertNewline(_:)): copySelected()
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
        return cell
    }
}

/// "404  Not Found" on one line (code colored by class), description smaller underneath.
private final class RowView: NSTableCellView {
    static let id = NSUserInterfaceItemIdentifier("RowView")
    private let title = NSTextField(labelWithString: "")
    private let detail = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = Self.id
        detail.font = .systemFont(ofSize: 12)
        detail.textColor = .secondaryLabelColor
        for f in [title, detail] {
            f.lineBreakMode = .byTruncatingTail
            f.translatesAutoresizingMaskIntoConstraints = false
            addSubview(f)
        }
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
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
