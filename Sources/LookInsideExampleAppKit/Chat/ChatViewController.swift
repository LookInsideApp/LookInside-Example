import AppKit

/// Chat as a nested split view: conversation list on the left, transcript on
/// the right — the shape a Mac messaging app actually takes.
final class ChatViewController: NSSplitViewController {
    private let store = ChatStore()
    private lazy var conversationListViewController = ConversationListViewController(store: store)
    private lazy var conversationDetailViewController = ConversationDetailViewController(store: store)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Wire the callback before the list loads: it selects the first
        // conversation while loading, and that selection must reach the
        // transcript.
        conversationListViewController.onSelectConversation = { [weak self] identifier in
            self?.conversationDetailViewController.show(conversationID: identifier)
        }

        let listItem = NSSplitViewItem(contentListWithViewController: conversationListViewController)
        listItem.minimumThickness = 260
        listItem.maximumThickness = 380
        listItem.holdingPriority = .defaultLow + 1
        addSplitViewItem(listItem)

        let detailItem = NSSplitViewItem(viewController: conversationDetailViewController)
        detailItem.minimumThickness = 360
        addSplitViewItem(detailItem)
    }
}

/// The conversation list: a view-based `NSTableView` with a search field and a
/// contextual menu standing in for the iOS swipe actions.
final class ConversationListViewController: NSViewController {
    private enum Section {
        case main
    }

    private let store: ChatStore
    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private var dataSource: NSTableViewDiffableDataSource<Section, Conversation.ID>!

    /// Called with the selected conversation, or `nil` when the selection is
    /// cleared.
    var onSelectConversation: ((Conversation.ID?) -> Void)?

    init(store: ChatStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search"
        searchField.delegate = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ConversationColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.style = .inset
        tableView.rowHeight = 60
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.backgroundColor = .clear
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.delegate = self
        tableView.menu = makeContextualMenu()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.applyDemoScrollerStyle()

        containerView.addSubview(searchField)
        containerView.addSubview(scrollView)

        // The window uses a full-size content view, so the search field hangs
        // off the safe area rather than the top edge — otherwise it would sit
        // under the toolbar and collide with the window title.
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = NSTableViewDiffableDataSource<Section, Conversation.ID>(
            tableView: tableView
        ) { [weak self] tableView, _, _, identifier in
            let existingCellView = tableView.makeView(
                withIdentifier: ConversationTableCellView.reuseIdentifier,
                owner: self
            ) as? ConversationTableCellView
            let cellView = existingCellView ?? ConversationTableCellView()
            cellView.identifier = ConversationTableCellView.reuseIdentifier
            if let conversation = self?.store.conversation(with: identifier) {
                cellView.configure(with: conversation)
            }
            return cellView
        }

        store.onChange = { [weak self] in
            self?.applySnapshotPreservingSelection()
        }
        applySnapshot(animated: false)

        if let firstIdentifier = dataSource.snapshot().itemIdentifiers.first {
            selectConversation(firstIdentifier)
        }
    }

    private func makeContextualMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Pin", action: #selector(togglePinnedForClickedRow), keyEquivalent: "")
        menu.addItem(withTitle: "Delete", action: #selector(deleteClickedRow), keyEquivalent: "")
        for menuItem in menu.items {
            menuItem.target = self
        }
        return menu
    }

    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Conversation.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(store.sortedConversations(matching: searchField.stringValue).map(\.id))
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    /// Re-applies the snapshot and reconfigures the visible rows (the
    /// diffable data source only re-renders rows whose identifiers moved),
    /// then puts the selection back on the same conversation.
    private func applySnapshotPreservingSelection() {
        let selectedIdentifier = tableView.selectedRow >= 0 ? dataSource.itemIdentifier(forRow: tableView.selectedRow) : nil
        applySnapshot(animated: true)
        tableView.enumerateAvailableRowViews { rowView, row in
            guard let identifier = self.dataSource.itemIdentifier(forRow: row),
                  let conversation = self.store.conversation(with: identifier),
                  let cellView = rowView.view(atColumn: 0) as? ConversationTableCellView
            else { return }
            cellView.configure(with: conversation)
        }
        if let selectedIdentifier, let row = dataSource.snapshot().indexOfItem(selectedIdentifier) {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    private func selectConversation(_ identifier: Conversation.ID) {
        guard let rowIndex = dataSource.snapshot().indexOfItem(identifier) else { return }
        tableView.selectRowIndexes(IndexSet(integer: rowIndex), byExtendingSelection: false)
    }

    private func identifierForClickedRow() -> Conversation.ID? {
        let clickedRow = tableView.clickedRow
        guard clickedRow >= 0 else { return nil }
        return dataSource.itemIdentifier(forRow: clickedRow)
    }

    @objc
    private func togglePinnedForClickedRow() {
        guard let identifier = identifierForClickedRow() else { return }
        store.togglePinned(identifier)
    }

    @objc
    private func deleteClickedRow() {
        guard let identifier = identifierForClickedRow() else { return }
        store.remove(identifier)
    }
}

extension ConversationListViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_: Notification) {
        applySnapshot(animated: true)
    }
}

extension ConversationListViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_: Notification) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, let identifier = dataSource.itemIdentifier(forRow: selectedRow) else {
            onSelectConversation?(nil)
            return
        }
        onSelectConversation?(identifier)
        store.markAsRead(identifier)
    }
}

/// The transcript: a header with the contact, a scrolling stack of bubbles,
/// and an input bar. With no conversation selected, an empty state replaces
/// all three.
final class ConversationDetailViewController: NSViewController {
    private let store: ChatStore
    private let contentView = NSView()
    private let headerAvatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 30)
    private let headerNameLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .headline),
        color: DemoPalette.primaryLabel
    )
    private let headerStatusLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption1),
        color: DemoPalette.secondaryLabel
    )
    private let scrollView = NSScrollView()
    private let documentView = FlippedView()
    private let messageStackView = NSStackView(orientation: .vertical, spacing: 4, alignment: .leading)
    private let inputTextField = NSTextField()
    private let sendButton = NSButton()
    private let emptyStateView = EmptyStateView(
        symbolName: "bubble.left.and.bubble.right",
        title: "No Conversation Selected",
        message: "Choose a conversation from the list."
    )

    private var conversationID: Conversation.ID?

    init(store: ChatStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        containerView.addSubview(emptyStateView)
        contentView.pinEdges(to: containerView)

        let headerView = makeHeaderView()
        let headerHairlineView = HairlineView()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.applyDemoScrollerStyle()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView
        documentView.addSubview(messageStackView)

        let inputRowStackView = makeInputRow()

        contentView.addSubview(headerView)
        contentView.addSubview(headerHairlineView)
        contentView.addSubview(scrollView)
        contentView.addSubview(inputRowStackView)

        let clipView = scrollView.contentView
        let readableWidthConstraint = messageStackView.widthAnchor.constraint(
            equalTo: documentView.widthAnchor,
            constant: -40
        )
        readableWidthConstraint.priority = .fillAvailableWidth

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            headerHairlineView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerHairlineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerHairlineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerHairlineView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: inputRowStackView.topAnchor, constant: -8),

            documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: clipView.widthAnchor),

            messageStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 16),
            messageStackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -16),
            messageStackView.centerXAnchor.constraint(equalTo: documentView.centerXAnchor),
            messageStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.chatContentMaximumWidth),
            readableWidthConstraint,

            inputRowStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            inputRowStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            inputRowStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            emptyStateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 24),
        ])

        // The list may have picked a conversation before this view loaded.
        reloadMessages()
    }

    private func makeHeaderView() -> NSView {
        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 1,
            alignment: .leading,
            views: [headerNameLabel, headerStatusLabel]
        )
        textColumnStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let actionButtons: [NSView] = [
            ("video", "Video call"),
            ("phone", "Voice call"),
            ("info.circle", "Conversation details"),
        ].map { symbolName, accessibilityLabel in
            let button = NSButton.demoSymbolButton(symbolName: symbolName, pointSize: 14)
            button.setAccessibilityLabel(accessibilityLabel)
            button.toolTip = accessibilityLabel
            return button
        }

        let headerStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [headerAvatarBadgeView, textColumnStackView, NSView.flexibleSpacer()] + actionButtons
        )
        headerStackView.setCustomSpacing(18, after: actionButtons[0])
        headerStackView.setCustomSpacing(18, after: actionButtons[1])
        headerStackView.edgeInsets = NSEdgeInsets(top: 10, left: 16, bottom: 10, right: 18)
        return headerStackView
    }

    private func makeInputRow() -> NSStackView {
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholderString = "Message"
        inputTextField.font = .preferredFont(forTextStyle: .body)
        inputTextField.bezelStyle = .roundedBezel
        inputTextField.controlSize = .large
        inputTextField.target = self
        inputTextField.action = #selector(sendMessage)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.image = NSImage.demoSymbol("arrow.up.circle.fill", pointSize: 22)
        sendButton.imagePosition = .imageOnly
        sendButton.isBordered = false
        sendButton.bezelStyle = .shadowlessSquare
        sendButton.contentTintColor = DemoPalette.accent
        sendButton.target = self
        sendButton.action = #selector(sendMessage)
        sendButton.setAccessibilityLabel("Send")

        let attachButton = NSButton.demoSymbolButton(symbolName: "plus.circle", pointSize: 18)
        attachButton.setAccessibilityLabel("Add attachment")

        return NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [attachButton, inputTextField, sendButton]
        )
    }

    func show(conversationID identifier: Conversation.ID?) {
        conversationID = identifier
        // Before the view loads, `loadView` renders the stored conversation.
        guard isViewLoaded else { return }
        reloadMessages()
    }

    private func applyConversationVisibility(hasConversation: Bool) {
        contentView.isHidden = !hasConversation
        emptyStateView.isHidden = hasConversation
    }

    private func reloadMessages() {
        for existingBubbleView in messageStackView.arrangedSubviews {
            messageStackView.removeArrangedSubview(existingBubbleView)
            existingBubbleView.removeFromSuperview()
        }

        guard let conversationID, let conversation = store.conversation(with: conversationID) else {
            applyConversationVisibility(hasConversation: false)
            return
        }
        applyConversationVisibility(hasConversation: true)

        headerAvatarBadgeView.configure(initials: conversation.initials, tint: conversation.tint)
        headerNameLabel.stringValue = conversation.name
        headerStatusLabel.stringValue = conversation.isOnline ? "Active now" : "Away"

        for (messageIndex, message) in conversation.messages.enumerated() {
            let bubbleView = MessageBubbleView(
                message: message,
                conversation: conversation,
                showsAvatar: showsAvatar(at: messageIndex, in: conversation),
                showsTimestamp: showsTimestamp(at: messageIndex, in: conversation)
            )
            messageStackView.addArrangedSubview(bubbleView)
            bubbleView.widthAnchor.constraint(equalTo: messageStackView.widthAnchor).isActive = true
        }

        view.layoutSubtreeIfNeeded()
        scrollToLatestMessage()
    }

    private func scrollToLatestMessage() {
        guard let lastBubbleView = messageStackView.arrangedSubviews.last else { return }
        lastBubbleView.scrollToVisible(lastBubbleView.bounds)
    }

    /// Only the last message in an incoming run carries the avatar.
    private func showsAvatar(at index: Int, in conversation: Conversation) -> Bool {
        let message = conversation.messages[index]
        guard !message.isFromMe else { return false }
        let nextIndex = index + 1
        guard nextIndex < conversation.messages.count else { return true }
        return conversation.messages[nextIndex].isFromMe
    }

    /// A timestamp separator appears at the top and after a 30-minute gap.
    private func showsTimestamp(at index: Int, in conversation: Conversation) -> Bool {
        guard index > 0 else { return true }
        let current = conversation.messages[index]
        let previous = conversation.messages[index - 1]
        return abs(previous.timestamp.timeIntervalSince(current.timestamp)) > 60 * 30
    }

    @objc
    private func sendMessage() {
        guard let conversationID else { return }
        let trimmed = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        store.append(ChatMessage(kind: .text(trimmed), isFromMe: true, timestamp: Date()), to: conversationID)
        inputTextField.stringValue = ""
        reloadMessages()
    }
}
