import AppKit

/// A conversation row in the chat sidebar. Custom `NSTableCellView` subclass
/// with named label properties.
final class ConversationTableCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("ConversationTableCellView")

    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 40)
    private let onlineIndicatorView = OnlineIndicatorView()
    private let pinImageView = NSImageView()
    private let nameLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body).withWeight(.semibold),
        color: DemoPalette.primaryLabel
    )
    private let timestampLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption1),
        color: DemoPalette.secondaryLabel,
        alignment: .right
    )
    private let previewLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption1),
        color: DemoPalette.secondaryLabel,
        maximumNumberOfLines: 2
    )
    private let unreadBadgeView = CardBoxView(cornerRadius: 8, fillColor: DemoPalette.accent)
    private let unreadCountLabel = NSTextField.demoLabel(
        font: .systemFont(ofSize: 10, weight: .bold),
        color: .white,
        alignment: .center
    )

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let avatarContainerView = NSView()
        avatarContainerView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainerView.addSubview(avatarBadgeView)
        avatarContainerView.addSubview(onlineIndicatorView)

        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.image = NSImage.demoSymbol("pin.fill", pointSize: 9)
        pinImageView.contentTintColor = .systemOrange
        pinImageView.setContentHuggingPriority(.required, for: .horizontal)

        timestampLabel.setContentHuggingPriority(.required, for: .horizontal)

        let titleRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 4,
            alignment: .firstBaseline,
            views: [pinImageView, nameLabel, NSView.flexibleSpacer(), timestampLabel]
        )

        unreadBadgeView.contentView?.addSubview(unreadCountLabel)
        if let badgeContentView = unreadBadgeView.contentView {
            unreadCountLabel.pinEdges(
                to: badgeContentView,
                insets: NSEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)
            )
        }

        let previewRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 6,
            alignment: .top,
            views: [previewLabel, unreadBadgeView]
        )

        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 3,
            alignment: .leading,
            views: [titleRowStackView, previewRowStackView]
        )

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .top,
            views: [avatarContainerView, textColumnStackView]
        )
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self, insets: NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

        NSLayoutConstraint.activate([
            avatarContainerView.widthAnchor.constraint(equalToConstant: 40),
            avatarContainerView.heightAnchor.constraint(equalToConstant: 40),
            avatarBadgeView.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            avatarBadgeView.topAnchor.constraint(equalTo: avatarContainerView.topAnchor),
            onlineIndicatorView.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor),
            onlineIndicatorView.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor),
            titleRowStackView.widthAnchor.constraint(equalTo: textColumnStackView.widthAnchor),
            previewRowStackView.widthAnchor.constraint(equalTo: textColumnStackView.widthAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with conversation: Conversation) {
        avatarBadgeView.configure(initials: conversation.initials, tint: conversation.tint)
        onlineIndicatorView.isHidden = !conversation.isOnline
        pinImageView.isHidden = !conversation.isPinned
        nameLabel.stringValue = conversation.name
        timestampLabel.stringValue = conversation.timestamp
        timestampLabel.textColor = conversation.unreadCount > 0 ? DemoPalette.accent : DemoPalette.secondaryLabel
        previewLabel.stringValue = conversation.lastMessage
        unreadCountLabel.stringValue = "\(conversation.unreadCount)"
        unreadBadgeView.isHidden = conversation.unreadCount == 0
    }
}
