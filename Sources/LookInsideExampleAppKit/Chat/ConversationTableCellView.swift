import AppKit

/// A conversation row in the chat sidebar. Custom `NSTableCellView` subclass
/// with named label properties.
final class ConversationTableCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("ConversationTableCellView")

    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 40)
    private var nameLeadingToAvatarConstraint: NSLayoutConstraint!
    private var nameLeadingToPinConstraint: NSLayoutConstraint!
    private var previewTrailingToBadgeConstraint: NSLayoutConstraint!
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
        font: .preferredFont(forTextStyle: .subheadline),
        color: DemoPalette.secondaryLabel
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

        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.image = NSImage.demoSymbol("pin.fill", pointSize: 9)
        pinImageView.contentTintColor = .systemOrange

        unreadBadgeView.contentView?.addSubview(unreadCountLabel)
        if let badgeContentView = unreadBadgeView.contentView {
            unreadCountLabel.pinEdges(
                to: badgeContentView,
                insets: NSEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
            )
        }

        for subview in [avatarBadgeView, onlineIndicatorView, pinImageView, nameLabel, timestampLabel, previewLabel, unreadBadgeView] {
            addSubview(subview)
        }

        // Explicit constraints rather than nested stack views, so every row
        // shares one layout: the name and preview truncate, the timestamp and
        // the unread badge hug a fixed trailing inset.
        for label in [nameLabel, previewLabel] {
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        for trailingView in [timestampLabel, unreadBadgeView] {
            trailingView.setContentCompressionResistancePriority(.required, for: .horizontal)
            trailingView.setContentHuggingPriority(.required, for: .horizontal)
        }

        nameLeadingToAvatarConstraint = nameLabel.leadingAnchor.constraint(equalTo: avatarBadgeView.trailingAnchor, constant: 10)
        nameLeadingToPinConstraint = nameLabel.leadingAnchor.constraint(equalTo: pinImageView.trailingAnchor, constant: 4)
        previewTrailingToBadgeConstraint = previewLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: unreadBadgeView.leadingAnchor,
            constant: -8
        )

        NSLayoutConstraint.activate([
            avatarBadgeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            avatarBadgeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            onlineIndicatorView.trailingAnchor.constraint(equalTo: avatarBadgeView.trailingAnchor, constant: 1),
            onlineIndicatorView.bottomAnchor.constraint(equalTo: avatarBadgeView.bottomAnchor, constant: 1),

            pinImageView.leadingAnchor.constraint(equalTo: avatarBadgeView.trailingAnchor, constant: 10),
            pinImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            nameLabel.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timestampLabel.leadingAnchor, constant: -8),

            timestampLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            timestampLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),

            previewLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            previewLabel.leadingAnchor.constraint(equalTo: avatarBadgeView.trailingAnchor, constant: 10),
            previewLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),

            unreadBadgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            unreadBadgeView.centerYAnchor.constraint(equalTo: previewLabel.centerYAnchor),
            unreadBadgeView.heightAnchor.constraint(equalToConstant: 16),
            unreadBadgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
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
        // Deactivate before activating so the two leading constraints never
        // hold at the same time.
        if conversation.isPinned {
            nameLeadingToAvatarConstraint.isActive = false
            nameLeadingToPinConstraint.isActive = true
        } else {
            nameLeadingToPinConstraint.isActive = false
            nameLeadingToAvatarConstraint.isActive = true
        }
        nameLabel.stringValue = conversation.name
        timestampLabel.stringValue = conversation.timestamp
        timestampLabel.textColor = conversation.unreadCount > 0 ? DemoPalette.accent : DemoPalette.secondaryLabel
        previewLabel.stringValue = conversation.lastMessage
        unreadCountLabel.stringValue = "\(conversation.unreadCount)"
        unreadBadgeView.isHidden = conversation.unreadCount == 0
        previewTrailingToBadgeConstraint.isActive = conversation.unreadCount > 0
    }
}
