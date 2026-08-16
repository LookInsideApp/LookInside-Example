import UIKit

/// The gradient banner attached to some posts.
final class HeroBannerView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let eyebrowLabel = UILabel()
    private let headlineLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .title3), color: .white, numberOfLines: 2)
    private let symbolImageView = UIImageView()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        headlineLabel.font = .preferredFont(forTextStyle: .title3).withWeight(.semibold)
        headlineLabel.layer.shadowColor = UIColor.black.cgColor
        headlineLabel.layer.shadowOpacity = 0.35
        headlineLabel.layer.shadowRadius = 6
        headlineLabel.layer.shadowOffset = CGSize(width: 0, height: 2)

        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.tintColor = UIColor.white.withAlphaComponent(0.55)
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
        symbolImageView.contentMode = .scaleAspectFit
        addSubview(symbolImageView)

        let captionStackView = UIStackView(
            axis: .vertical,
            spacing: 4,
            alignment: .leading,
            arrangedSubviews: [eyebrowLabel, headlineLabel]
        )
        addSubview(captionStackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 160),
            captionStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            captionStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            captionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            symbolImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            symbolImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with hero: SocialHero) {
        gradientLayer.colors = hero.gradient.map(\.color.cgColor)
        symbolImageView.image = UIImage(systemName: hero.symbolName)
        headlineLabel.text = hero.headline
        eyebrowLabel.attributedText = NSAttributedString(
            string: hero.eyebrow.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .kern: 2,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            ]
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

/// A feed post. Everything is a plain subview stack inside one rounded card;
/// the optional tag row and hero banner are hidden rather than removed so the
/// hierarchy stays stable across cell reuse.
final class PostCell: UICollectionViewCell {
    static let reuseIdentifier = "PostCell"

    private let cardView = CardView()
    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 44)
    private let authorLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.primaryLabel)
    private let verifiedImageView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
    private let handleLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1), color: DemoPalette.secondaryLabel)
    private let bodyLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .body), color: DemoPalette.primaryLabel, numberOfLines: 0)
    private let tagRowStackView = UIStackView(axis: .horizontal, spacing: 6)
    private let heroBannerView = HeroBannerView()
    private let hairlineView = HairlineView()

    private let likeButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let bookmarkButton = UIButton(type: .system)

    var onToggleLike: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(cardView)
        cardView.pinEdges(to: contentView)

        authorLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        verifiedImageView.translatesAutoresizingMaskIntoConstraints = false
        verifiedImageView.tintColor = .systemBlue
        verifiedImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1)
        verifiedImageView.setContentHuggingPriority(.required, for: .horizontal)

        let nameRowStackView = UIStackView(
            axis: .horizontal,
            spacing: 4,
            alignment: .center,
            arrangedSubviews: [authorLabel, verifiedImageView, UIView.flexibleSpacer()]
        )

        let identityStackView = UIStackView(
            axis: .vertical,
            spacing: 1,
            alignment: .leading,
            arrangedSubviews: [nameRowStackView, handleLabel]
        )

        let moreButton = UIButton(type: .system)
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = DemoPalette.secondaryLabel
        moreButton.setContentHuggingPriority(.required, for: .horizontal)

        let headerStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [avatarBadgeView, identityStackView, moreButton]
        )

        configureActionButton(likeButton, symbolName: "heart")
        likeButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        configureActionButton(commentButton, symbolName: "bubble.left")
        configureActionButton(shareButton, symbolName: "arrowshape.turn.up.right")

        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = DemoPalette.secondaryLabel

        let actionRowStackView = UIStackView(
            axis: .horizontal,
            spacing: 14,
            alignment: .center,
            arrangedSubviews: [likeButton, commentButton, shareButton, UIView.flexibleSpacer(), bookmarkButton]
        )

        let columnStackView = UIStackView(
            axis: .vertical,
            spacing: 12,
            arrangedSubviews: [
                headerStackView,
                bodyLabel,
                tagRowStackView,
                heroBannerView,
                hairlineView,
                actionRowStackView,
            ]
        )
        cardView.addSubview(columnStackView)
        columnStackView.pinEdges(to: cardView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureActionButton(_ button: UIButton, symbolName: String) {
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.image = UIImage(systemName: symbolName)
        buttonConfiguration.imagePadding = 6
        buttonConfiguration.contentInsets = .zero
        buttonConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            return outgoing
        }
        button.configuration = buttonConfiguration
        button.tintColor = DemoPalette.secondaryLabel
    }

    func configure(with post: SocialPost) {
        avatarBadgeView.configure(initials: post.initials, tint: post.tint)
        authorLabel.text = post.author
        verifiedImageView.isHidden = !post.isVerified
        handleLabel.text = "\(post.handle) · \(post.timeAgo)"
        bodyLabel.text = post.body

        for existingTag in tagRowStackView.arrangedSubviews {
            tagRowStackView.removeArrangedSubview(existingTag)
            existingTag.removeFromSuperview()
        }
        for tag in post.tags {
            let tagLabel = UILabel(
                text: "#\(tag)",
                font: .preferredFont(forTextStyle: .caption1).withWeight(.medium),
                color: DemoPalette.accent
            )
            tagRowStackView.addArrangedSubview(tagLabel)
        }
        tagRowStackView.addArrangedSubview(UIView.flexibleSpacer())
        tagRowStackView.isHidden = post.tags.isEmpty

        if let hero = post.hero {
            heroBannerView.configure(with: hero)
            heroBannerView.isHidden = false
        } else {
            heroBannerView.isHidden = true
        }

        likeButton.configuration?.image = UIImage(systemName: post.isLiked ? "heart.fill" : "heart")
        likeButton.configuration?.title = SocialCountFormatter.abbreviated(post.likeCount)
        likeButton.tintColor = post.isLiked ? .systemPink : DemoPalette.secondaryLabel
        commentButton.configuration?.title = SocialCountFormatter.abbreviated(post.commentCount)
        shareButton.configuration?.title = SocialCountFormatter.abbreviated(post.shareCount)
    }

    @objc
    private func toggleLike() {
        onToggleLike?()
    }
}
