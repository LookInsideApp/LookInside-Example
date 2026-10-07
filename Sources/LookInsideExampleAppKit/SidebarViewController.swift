import AppKit

/// One row in the source list. A reference type because `NSOutlineView`
/// identifies items by object identity.
final class SidebarNode {
    let title: String
    let symbolName: String?
    let destination: DemoDestination?
    let children: [SidebarNode]

    init(title: String, symbolName: String? = nil, destination: DemoDestination? = nil, children: [SidebarNode] = []) {
        self.title = title
        self.symbolName = symbolName
        self.destination = destination
        self.children = children
    }

    convenience init(destination: DemoDestination) {
        self.init(title: destination.title, symbolName: destination.symbolName, destination: destination)
    }

    var isGroup: Bool {
        destination == nil
    }
}

/// The source list. Traditional data source and delegate rather than a
/// diffable one — `NSOutlineView` has no diffable data source, and the tree
/// here is fixed: a top-level Welcome row and one group of demos.
final class SidebarViewController: NSViewController {
    private let scrollView = NSScrollView()
    private let outlineView = NSOutlineView()

    private let rootNodes: [SidebarNode] = [
        SidebarNode(destination: .welcome),
        SidebarNode(title: "Demos", children: [
            SidebarNode(destination: .music),
            SidebarNode(destination: .feed),
            SidebarNode(destination: .chat),
            SidebarNode(destination: .controls),
        ]),
    ]

    var onSelectDestination: ((DemoDestination) -> Void)?

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SidebarColumn"))
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .default
        outlineView.floatsGroupRows = false
        outlineView.indentationPerLevel = 0
        outlineView.dataSource = self
        outlineView.delegate = self

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.applyDemoScrollerStyle()
        containerView.addSubview(scrollView)
        scrollView.pinEdges(to: containerView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard outlineView.selectedRow < 0 else { return }
        for node in rootNodes where node.isGroup {
            outlineView.expandItem(node)
        }
        select(.welcome)
    }

    /// Selects the row for `destination`, which in turn shows it.
    func select(_ destination: DemoDestination) {
        let allNodes = rootNodes + rootNodes.flatMap(\.children)
        guard let node = allNodes.first(where: { $0.destination == destination }) else { return }
        let row = outlineView.row(forItem: node)
        guard row >= 0 else { return }
        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
}

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? SidebarNode else { return rootNodes.count }
        return node.children.count
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? SidebarNode else { return rootNodes[index] }
        return node.children[index]
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? SidebarNode)?.children.isEmpty == false
    }
}

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_: NSOutlineView, isGroupItem item: Any) -> Bool {
        (item as? SidebarNode)?.isGroup ?? false
    }

    func outlineView(_: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        (item as? SidebarNode)?.destination != nil
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? SidebarNode else { return nil }

        let identifier = NSUserInterfaceItemIdentifier(node.isGroup ? "SidebarGroupCell" : "SidebarItemCell")
        let existingCellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? SidebarItemCellView
        let cellView = existingCellView ?? SidebarItemCellView(isGroup: node.isGroup)
        cellView.identifier = identifier
        cellView.configure(with: node)
        return cellView
    }

    func outlineViewSelectionDidChange(_: Notification) {
        let selectedRow = outlineView.selectedRow
        guard selectedRow >= 0,
              let node = outlineView.item(atRow: selectedRow) as? SidebarNode,
              let destination = node.destination
        else { return }
        onSelectDestination?(destination)
    }
}

/// The sidebar row view. A custom `NSTableCellView` subclass with its own
/// label property — the inherited `textField` outlet stays untouched.
final class SidebarItemCellView: NSTableCellView {
    private let symbolImageView = NSImageView()
    private let titleLabel: NSTextField

    init(isGroup: Bool) {
        titleLabel = NSTextField.demoLabel(
            font: isGroup
                ? .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
                : .preferredFont(forTextStyle: .body),
            color: isGroup ? DemoPalette.secondaryLabel : DemoPalette.primaryLabel
        )
        super.init(frame: .zero)

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.imageScaling = .scaleProportionallyDown
        symbolImageView.contentTintColor = DemoPalette.accent

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 8,
            alignment: .centerY,
            views: isGroup ? [titleLabel] : [symbolImageView, titleLabel]
        )
        addSubview(rowStackView)

        NSLayoutConstraint.activate([
            rowStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            rowStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            symbolImageView.widthAnchor.constraint(equalToConstant: 18),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with node: SidebarNode) {
        titleLabel.stringValue = node.title
        if let symbolName = node.symbolName {
            symbolImageView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        }
    }
}

extension NSFont {
    func withWeight(_ weight: NSFont.Weight) -> NSFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [NSFontDescriptor.TraitKey.weight: weight],
        ])
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
