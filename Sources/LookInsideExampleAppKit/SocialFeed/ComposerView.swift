import AppKit

/// The inline composer above the feed.
final class ComposerView: NSView {
    private let cardBoxView = CardBoxView()
    private let avatarBadgeView = AvatarBadgeView(initials: "Y", tint: .blue, diameter: 34)
    private let inputTextField = NSTextField()
    private let postButton = NSButton()

    var onPublish: ((String) -> Void)?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(cardBoxView)
        cardBoxView.pinEdges(to: self)

        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholderString = "Share something with your friends..."
        inputTextField.font = .preferredFont(forTextStyle: .body)
        inputTextField.bezelStyle = .roundedBezel
        inputTextField.isEditable = true
        inputTextField.isSelectable = true
        inputTextField.target = self
        inputTextField.action = #selector(publish)
        inputTextField.delegate = self

        let attachmentButtons: [NSView] = [
            ("photo", DemoTint.green),
            ("video", .pink),
            ("location", .blue),
            ("face.smiling", .orange),
        ].map { symbolName, tint in
            let button = NSButton.demoSymbolButton(symbolName: symbolName, pointSize: 14)
            button.contentTintColor = tint.color
            return button
        }

        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.title = "Post"
        postButton.bezelStyle = .rounded
        postButton.controlSize = .regular
        postButton.keyEquivalent = "\r"
        postButton.target = self
        postButton.action = #selector(publish)
        postButton.isEnabled = false

        let actionRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 14,
            alignment: .centerY,
            views: attachmentButtons + [NSView.flexibleSpacer(), postButton]
        )

        let inputColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 10,
            alignment: .leading,
            views: [inputTextField, actionRowStackView]
        )

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 12,
            alignment: .top,
            views: [avatarBadgeView, inputColumnStackView]
        )
        cardBoxView.contentView?.addSubview(rowStackView)
        if let cardContentView = cardBoxView.contentView {
            rowStackView.pinEdges(
                to: cardContentView,
                insets: NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
            )
        }

        NSLayoutConstraint.activate([
            inputTextField.widthAnchor.constraint(equalTo: inputColumnStackView.widthAnchor),
            actionRowStackView.widthAnchor.constraint(equalTo: inputColumnStackView.widthAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func publish() {
        let trimmed = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onPublish?(trimmed)
        inputTextField.stringValue = ""
        postButton.isEnabled = false
    }
}

extension ComposerView: NSTextFieldDelegate {
    func controlTextDidChange(_: Notification) {
        let trimmed = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        postButton.isEnabled = !trimmed.isEmpty
    }
}
