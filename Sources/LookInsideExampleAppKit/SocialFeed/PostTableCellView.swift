import AppKit

/// The gradient banner attached to some posts.
final class HeroBannerView: GradientView {
    private let eyebrowLabel = NSTextField.demoLabel(font: .systemFont(ofSize: 11, weight: .bold), color: .white)
    private let headlineLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .title3).withWeight(.semibold),
        color: .white,
        maximumNumberOfLines: 2
    )
    private let symbolImageView = NSImageView()

    init() {
        super.init(cornerRadius: 12)

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.contentTintColor = NSColor.white.withAlphaComponent(0.55)
        symbolImageView.imageScaling = .scaleProportionallyDown
        addSubview(symbolImageView)

        let captionStackView = NSStackView(
            orientation: .vertical,
            spacing: 4,
            alignment: .leading,
            views: [eyebrowLabel, headlineLabel]
        )
        addSubview(captionStackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 160),
            captionStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            captionStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            captionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            symbolImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            symbolImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            symbolImageView.widthAnchor.constraint(equalToConstant: 64),
            symbolImageView.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    func configure(with hero: SocialHero) {
        setColors(hero.gradient.map(\.color))
        symbolImageView.image = NSImage.demoSymbol(hero.symbolName, pointSize: 56, weight: .light)
        headlineLabel.stringValue = hero.headline
        eyebrowLabel.attributedStringValue = NSAttributedString(
            string: hero.eyebrow.uppercased(),
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold),
                .kern: 2,
                .foregroundColor: NSColor.white.withAlphaComponent(0.85),
            ]
        )
    }
}

/// A feed post row. A custom `NSTableCellView` subclass as the AppKit
/// conventions require — the inherited `textField` outlet is left alone and
/// every label is an explicitly named property.
final class PostTableCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("PostTableCellView")

    private let cardBoxView = CardBoxView()
    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 40)
    private let authorLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body).withWeight(.semibold),
        color: DemoPalette.primaryLabel
    )
    private let verifiedImageView = NSImageView()
    private let handleLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption1),
        color: DemoPalette.secondaryLabel
    )
    private let bodyLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body),
        color: DemoPalette.primaryLabel,
        maximumNumberOfLines: 0
    )
    private let tagRowStackView = NSStackView(orientation: .horizontal, spacing: 6, alignment: .firstBaseline)
    private let heroBannerView = HeroBannerView()
    private let hairlineView = HairlineView()

    private let likeButton = NSButton()
    private let commentButton = NSButton()
    private let shareButton = NSButton()
    private let bookmarkButton = NSButton()

    var onToggleLike: (() -> Void)?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(cardBoxView)
        cardBoxView.pinEdges(to: self, insets: NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))

        verifiedImageView.translatesAutoresizingMaskIntoConstraints = false
        verifiedImageView.image = NSImage.demoSymbol("checkmark.seal.fill", pointSize: 11)
        verifiedImageView.contentTintColor = .systemBlue
        verifiedImageView.setContentHuggingPriority(.required, for: .horizontal)

        let nameRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 4,
            alignment: .centerY,
            views: [authorLabel, verifiedImageView, NSView.flexibleSpacer()]
        )

        let identityColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 1,
            alignment: .leading,
            views: [nameRowStackView, handleLabel]
        )

        let moreButton = NSButton.demoSymbolButton(symbolName: "ellipsis", pointSize: 13)

        let headerRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 12,
            alignment: .centerY,
            views: [avatarBadgeView, identityColumnStackView, moreButton]
        )

        configureActionButton(likeButton, symbolName: "heart", target: self, action: #selector(toggleLike))
        configureActionButton(commentButton, symbolName: "bubble.left")
        configureActionButton(shareButton, symbolName: "arrowshape.turn.up.right")
        configureActionButton(bookmarkButton, symbolName: "bookmark", showsTitle: false)

        let actionRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 16,
            alignment: .centerY,
            views: [likeButton, commentButton, shareButton, NSView.flexibleSpacer(), bookmarkButton]
        )

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 12,
            alignment: .leading,
            views: [
                headerRowStackView,
                bodyLabel,
                tagRowStackView,
                heroBannerView,
                hairlineView,
                actionRowStackView,
            ]
        )
        cardBoxView.contentView?.addSubview(columnStackView)
        if let cardContentView = cardBoxView.contentView {
            columnStackView.pinEdges(
                to: cardContentView,
                insets: NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            )
            NSLayoutConstraint.activate([
                headerRowStackView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
                bodyLabel.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
                tagRowStackView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
                heroBannerView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
                hairlineView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
                actionRowStackView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
            ])
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureActionButton(
        _ button: NSButton,
        symbolName: String,
        showsTitle: Bool = true,
        target: AnyObject? = nil,
        action: Selector? = nil
    ) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.image = NSImage.demoSymbol(symbolName, pointSize: 13)
        button.imagePosition = showsTitle ? .imageLeading : .imageOnly
        button.isBordered = false
        button.bezelStyle = .shadowlessSquare
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.contentTintColor = DemoPalette.secondaryLabel
        button.target = target
        button.action = action
    }

    func configure(with post: SocialPost) {
        avatarBadgeView.configure(initials: post.initials, tint: post.tint)
        authorLabel.stringValue = post.author
        verifiedImageView.isHidden = !post.isVerified
        handleLabel.stringValue = "\(post.handle) · \(post.timeAgo)"
        bodyLabel.stringValue = post.body

        for existingTagView in tagRowStackView.arrangedSubviews {
            tagRowStackView.removeArrangedSubview(existingTagView)
            existingTagView.removeFromSuperview()
        }
        for tag in post.tags {
            tagRowStackView.addArrangedSubview(
                NSTextField.demoLabel(
                    "#\(tag)",
                    font: .preferredFont(forTextStyle: .caption1).withWeight(.medium),
                    color: DemoPalette.accent
                )
            )
        }
        tagRowStackView.addArrangedSubview(NSView.flexibleSpacer())
        tagRowStackView.isHidden = post.tags.isEmpty

        if let hero = post.hero {
            heroBannerView.configure(with: hero)
            heroBannerView.isHidden = false
        } else {
            heroBannerView.isHidden = true
        }

        likeButton.image = NSImage.demoSymbol(post.isLiked ? "heart.fill" : "heart", pointSize: 13)
        likeButton.title = SocialCountFormatter.abbreviated(post.likeCount)
        likeButton.contentTintColor = post.isLiked ? .systemPink : DemoPalette.secondaryLabel
        commentButton.title = SocialCountFormatter.abbreviated(post.commentCount)
        shareButton.title = SocialCountFormatter.abbreviated(post.shareCount)
    }

    @objc
    private func toggleLike() {
        onToggleLike?()
    }
}
