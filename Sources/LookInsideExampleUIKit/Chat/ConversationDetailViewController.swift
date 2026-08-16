import UIKit

/// A single conversation: a message table plus a growing input bar pinned to
/// the keyboard via `view.keyboardLayoutGuide`.
final class ConversationDetailViewController: UIViewController {
    private let store: ChatStore
    private let conversationID: Conversation.ID

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBarView = UIView()
    private let inputTextView = UITextView()
    private let inputPlaceholderLabel = UILabel(text: "Message", font: .preferredFont(forTextStyle: .body), color: DemoPalette.tertiaryLabel)
    private let sendButton = UIButton(type: .system)
    private let inputCapsuleView = UIView()
    private var inputTextViewHeightConstraint: NSLayoutConstraint?

    private var conversation: Conversation? {
        store.conversation(with: conversationID)
    }

    init(store: ChatStore, conversationID: Conversation.ID) {
        self.store = store
        self.conversationID = conversationID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = conversation?.name
        view.backgroundColor = DemoPalette.groupedBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: nil, action: nil),
            UIBarButtonItem(image: UIImage(systemName: "phone"), style: .plain, target: nil, action: nil),
            UIBarButtonItem(image: UIImage(systemName: "video"), style: .plain, target: nil, action: nil),
        ]

        buildInputBar()
        buildTableView()

        store.markAsRead(conversationID)
        tableView.reloadData()
        scrollToLatestMessage(animated: false)
    }

    // MARK: - Layout

    private func buildTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = DemoPalette.groupedBackground
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.keyboardDismissMode = .interactive
        tableView.register(MessageBubbleCell.self, forCellReuseIdentifier: MessageBubbleCell.reuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBarView.topAnchor),
        ])
    }

    private func buildInputBar() {
        inputBarView.translatesAutoresizingMaskIntoConstraints = false
        inputBarView.backgroundColor = DemoPalette.groupedBackground
        view.addSubview(inputBarView)

        let topHairlineView = HairlineView()
        inputBarView.addSubview(topHairlineView)

        let attachButton = UIButton(type: .system)
        attachButton.setImage(
            UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)),
            for: .normal
        )
        attachButton.tintColor = DemoPalette.secondaryLabel
        attachButton.setContentHuggingPriority(.required, for: .horizontal)

        inputCapsuleView.translatesAutoresizingMaskIntoConstraints = false
        inputCapsuleView.backgroundColor = DemoPalette.cardBackground

        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.font = .preferredFont(forTextStyle: .body)
        inputTextView.backgroundColor = .clear
        inputTextView.textContainerInset = UIEdgeInsets(top: 9, left: 4, bottom: 9, right: 4)
        inputTextView.isScrollEnabled = false
        inputTextView.delegate = self

        inputPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.addSubview(inputPlaceholderLabel)

        let emojiButton = UIButton(type: .system)
        emojiButton.setImage(UIImage(systemName: "face.smiling"), for: .normal)
        emojiButton.tintColor = DemoPalette.secondaryLabel
        emojiButton.setContentHuggingPriority(.required, for: .horizontal)

        let capsuleStackView = UIStackView(
            axis: .horizontal,
            spacing: 8,
            alignment: .bottom,
            arrangedSubviews: [inputTextView, emojiButton]
        )
        inputCapsuleView.addSubview(capsuleStackView)
        capsuleStackView.pinEdges(to: inputCapsuleView, insets: UIEdgeInsets(top: 0, left: 14, bottom: 6, right: 14))

        sendButton.setImage(
            UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)),
            for: .normal
        )
        sendButton.setContentHuggingPriority(.required, for: .horizontal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .bottom,
            arrangedSubviews: [attachButton, inputCapsuleView, sendButton]
        )
        inputBarView.addSubview(rowStackView)

        let heightConstraint = inputTextView.heightAnchor.constraint(equalToConstant: 38)
        inputTextViewHeightConstraint = heightConstraint

        // Same capped-and-centred treatment the SwiftUI version applies to its
        // input bar: full width on iPhone, capped and centred on iPad.
        let preferredRowWidthConstraint = rowStackView.widthAnchor.constraint(
            equalTo: inputBarView.widthAnchor,
            constant: -28
        )
        preferredRowWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            inputBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            topHairlineView.topAnchor.constraint(equalTo: inputBarView.topAnchor),
            topHairlineView.leadingAnchor.constraint(equalTo: inputBarView.leadingAnchor),
            topHairlineView.trailingAnchor.constraint(equalTo: inputBarView.trailingAnchor),

            rowStackView.topAnchor.constraint(equalTo: inputBarView.topAnchor, constant: 10),
            rowStackView.bottomAnchor.constraint(equalTo: inputBarView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            rowStackView.centerXAnchor.constraint(equalTo: inputBarView.centerXAnchor),
            rowStackView.leadingAnchor.constraint(greaterThanOrEqualTo: inputBarView.leadingAnchor, constant: 14),
            rowStackView.trailingAnchor.constraint(lessThanOrEqualTo: inputBarView.trailingAnchor, constant: -14),
            rowStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.chatContentMaximumWidth),
            preferredRowWidthConstraint,

            heightConstraint,
            inputPlaceholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 9),
            inputPlaceholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 9),
        ])

        updateSendButtonSymbol()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        inputCapsuleView.layer.cornerRadius = min(inputCapsuleView.bounds.height / 2, 22)
    }

    // MARK: - Messages

    private func scrollToLatestMessage(animated: Bool) {
        guard let messageCount = conversation?.messages.count, messageCount > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: messageCount - 1, section: 0), at: .bottom, animated: animated)
    }

    private func updateSendButtonSymbol() {
        let hasDraft = !inputTextView.text.trimmingCharacters(in: .whitespaces).isEmpty
        sendButton.setImage(
            UIImage(
                systemName: hasDraft ? "arrow.up.circle.fill" : "mic.fill",
                withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)
            ),
            for: .normal
        )
        inputPlaceholderLabel.isHidden = !inputTextView.text.isEmpty
    }

    @objc
    private func sendMessage() {
        let trimmed = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        store.append(ChatMessage(kind: .text(trimmed), isFromMe: true, timestamp: Date()), to: conversationID)
        inputTextView.text = ""
        inputTextViewHeightConstraint?.constant = 38
        updateSendButtonSymbol()

        tableView.reloadData()
        scrollToLatestMessage(animated: true)
    }
}

extension ConversationDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSendButtonSymbol()

        let maximumHeight = ceil((textView.font?.lineHeight ?? 20) * 5) + 18
        let fittingHeight = textView.sizeThatFits(
            CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        ).height
        let clampedHeight = min(max(38, fittingHeight), maximumHeight)
        textView.isScrollEnabled = fittingHeight > maximumHeight
        inputTextViewHeightConstraint?.constant = clampedHeight
    }
}

extension ConversationDetailViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        conversation?.messages.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageBubbleCell.reuseIdentifier, for: indexPath)
        guard let bubbleCell = cell as? MessageBubbleCell, let conversation else { return cell }

        let message = conversation.messages[indexPath.row]
        bubbleCell.configure(
            message: message,
            conversation: conversation,
            showsAvatar: showsAvatar(at: indexPath.row, in: conversation),
            showsTimestamp: showsTimestamp(at: indexPath.row, in: conversation)
        )
        return bubbleCell
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
}

extension ConversationDetailViewController: UITableViewDelegate {}
