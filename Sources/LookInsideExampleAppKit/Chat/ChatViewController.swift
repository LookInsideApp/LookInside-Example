import AppKit

/// Chat as a nested split view: conversation list on the left, transcript on
/// the right — the shape a Mac messaging app actually takes.
final class ChatViewController: NSSplitViewController {
    private let store = ChatStore()
    private lazy var conversationListViewController = ConversationListViewController(store: store)
    private lazy var conversationDetailViewController = ConversationDetailViewController(store: store)

    override func viewDidLoad() {
        super.viewDidLoad()

        let listItem = NSSplitViewItem(contentListWithViewController: conversationListViewController)
        listItem.minimumThickness = 240
        listItem.maximumThickness = 360
        addSplitViewItem(listItem)

        let detailItem = NSSplitViewItem(viewController: conversationDetailViewController)
        detailItem.minimumThickness = 320
        addSplitViewItem(detailItem)

        conversationListViewController.onSelectConversation = { [weak self] identifier in
            self?.conversationDetailViewController.show(conversationID: identifier)
        }
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

    var onSelectConversation: ((Conversation.ID) -> Void)?

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
        searchField.placeholderString = "Search messages"
        searchField.delegate = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ConversationColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.style = .inset
        tableView.usesAutomaticRowHeights = true
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.menu = makeContextualMenu()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        containerView.addSubview(searchField)
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),

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
            self?.applySnapshot(animated: true)
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
        guard selectedRow >= 0, let identifier = dataSource.itemIdentifier(forRow: selectedRow) else { return }
        store.markAsRead(identifier)
        onSelectConversation?(identifier)
    }
}

/// The transcript: a scrolling stack of bubbles plus an input bar.
final class ConversationDetailViewController: NSViewController {
    private let store: ChatStore
    private let scrollView = NSScrollView()
    private let documentView = FlippedView()
    private let messageStackView = NSStackView(orientation: .vertical, spacing: 4, alignment: .leading)
    private let inputTextField = NSTextField()
    private let sendButton = NSButton()
    private let placeholderLabel = NSTextField.demoLabel(
        "Pick a conversation",
        font: .preferredFont(forTextStyle: .title3),
        color: DemoPalette.secondaryLabel,
        alignment: .center
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

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView
        documentView.addSubview(messageStackView)

        let hairlineView = HairlineView()

        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholderString = "Message"
        inputTextField.font = .preferredFont(forTextStyle: .body)
        inputTextField.bezelStyle = .roundedBezel
        inputTextField.target = self
        inputTextField.action = #selector(sendMessage)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.image = NSImage.demoSymbol("arrow.up.circle.fill", pointSize: 18)
        sendButton.imagePosition = .imageOnly
        sendButton.isBordered = false
        sendButton.bezelStyle = .shadowlessSquare
        sendButton.contentTintColor = DemoPalette.accent
        sendButton.target = self
        sendButton.action = #selector(sendMessage)

        let attachButton = NSButton.demoSymbolButton(symbolName: "plus.circle", pointSize: 16)

        let inputRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [attachButton, inputTextField, sendButton]
        )

        containerView.addSubview(scrollView)
        containerView.addSubview(hairlineView)
        containerView.addSubview(inputRowStackView)
        containerView.addSubview(placeholderLabel)

        let clipView = scrollView.contentView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: hairlineView.topAnchor),

            documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: clipView.widthAnchor),

            messageStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 16),
            messageStackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -16),
            messageStackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 16),
            messageStackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -16),

            hairlineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hairlineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hairlineView.bottomAnchor.constraint(equalTo: inputRowStackView.topAnchor, constant: -10),

            inputRowStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            inputRowStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            inputRowStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            placeholderLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
    }

    func show(conversationID identifier: Conversation.ID) {
        conversationID = identifier
        reloadMessages()
    }

    private func reloadMessages() {
        for existingBubbleView in messageStackView.arrangedSubviews {
            messageStackView.removeArrangedSubview(existingBubbleView)
            existingBubbleView.removeFromSuperview()
        }

        guard let conversationID, let conversation = store.conversation(with: conversationID) else {
            placeholderLabel.isHidden = false
            return
        }
        placeholderLabel.isHidden = true

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
