import UIKit

/// A 640×520 post card: author header, body, tags, an optional gradient
/// banner and the like, comment and share counts.
///
/// Built by hand rather than from a content configuration, so it animates its
/// own focus: the card scales up and casts a shadow, in step with the focus
/// engine's animation.
final class PostCell: UICollectionViewCell {
    private let avatarBadgeView = AvatarBadgeView(diameter: 72)
    private let authorLabel = UILabel(
        text: nil,
        font: .preferredFont(forTextStyle: .callout).withWeight(.semibold),
        color: DemoPalette.primaryLabel
    )
    private let verifiedImageView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
    private let handleLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1), color: DemoPalette.secondaryLabel)
    private let bodyLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .callout), color: DemoPalette.primaryLabel, numberOfLines: 3)
    private let tagsLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1).withWeight(.medium), color: DemoPalette.accent)
    private let heroBannerView = HeroBannerView()
    private let likeLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1).withWeight(.medium), color: DemoPalette.secondaryLabel)
    private let commentLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1).withWeight(.medium), color: DemoPalette.secondaryLabel)
    private let shareLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1).withWeight(.medium), color: DemoPalette.secondaryLabel)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = DemoPalette.panelBackground
        contentView.layer.cornerRadius = DemoMetrics.panelCornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 16)

        verifiedImageView.translatesAutoresizingMaskIntoConstraints = false
        verifiedImageView.tintColor = .systemBlue
        verifiedImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1)

        let nameStackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, arrangedSubviews: [authorLabel, verifiedImageView])
        let identityStackView = UIStackView(axis: .vertical, spacing: 2, alignment: .leading, arrangedSubviews: [nameStackView, handleLabel])
        let headerStackView = UIStackView(axis: .horizontal, spacing: 18, alignment: .center, arrangedSubviews: [avatarBadgeView, identityStackView])

        let countsStackView = UIStackView(axis: .horizontal, spacing: 36, arrangedSubviews: [likeLabel, commentLabel, shareLabel])

        let cardStackView = UIStackView(
            axis: .vertical,
            spacing: 18,
            alignment: .fill,
            arrangedSubviews: [headerStackView, bodyLabel, tagsLabel, heroBannerView, UIView.flexibleSpacer(), countsStackView]
        )
        contentView.addSubview(cardStackView)
        cardStackView.pinEdges(to: contentView, insets: UIEdgeInsets(top: 28, left: 28, bottom: 28, right: 28))
        heroBannerView.heightAnchor.constraint(equalToConstant: 140).isActive = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with post: SocialPost) {
        avatarBadgeView.configure(initials: post.initials, tint: post.tint)
        authorLabel.text = post.author
        verifiedImageView.isHidden = !post.isVerified
        handleLabel.text = "\(post.handle) · \(post.timeAgo)"
        bodyLabel.text = post.body
        tagsLabel.text = post.tags.map { "#\($0)" }.joined(separator: "  ")
        tagsLabel.textColor = post.tint.color
        tagsLabel.isHidden = post.tags.isEmpty
        if let hero = post.hero {
            heroBannerView.configure(with: hero)
            heroBannerView.isHidden = false
        } else {
            heroBannerView.isHidden = true
        }

        likeLabel.attributedText = Self.countText(
            symbolName: post.isLiked ? "heart.fill" : "heart",
            count: post.likeCount,
            color: post.isLiked ? .systemPink : DemoPalette.secondaryLabel
        )
        commentLabel.attributedText = Self.countText(symbolName: "bubble.left", count: post.commentCount, color: DemoPalette.secondaryLabel)
        shareLabel.attributedText = Self.countText(symbolName: "arrowshape.turn.up.right", count: post.shareCount, color: DemoPalette.secondaryLabel)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations { [self] in
            transform = isFocused ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
            layer.shadowOpacity = isFocused ? 0.35 : 0
        }
    }

    /// "♥ 1.3K" as one attributed string: an inline symbol and the count.
    private static func countText(symbolName: String, count: Int, color: UIColor) -> NSAttributedString {
        let symbolAttachment = NSTextAttachment()
        symbolAttachment.image = UIImage(systemName: symbolName)?.withTintColor(color, renderingMode: .alwaysOriginal)
        let countText = NSMutableAttributedString(attachment: symbolAttachment)
        countText.append(NSAttributedString(
            string: "  " + SocialCountFormatter.abbreviated(count),
            attributes: [.foregroundColor: color]
        ))
        return countText
    }
}

/// The gradient strip some posts carry. The gradient is a bare
/// `CAGradientLayer`; the eyebrow and headline are labels above it.
private final class HeroBannerView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let symbolImageView = UIImageView()
    private let eyebrowLabel = UILabel()
    private let headlineLabel = UILabel(
        text: nil,
        font: .preferredFont(forTextStyle: .callout).withWeight(.semibold),
        color: .white
    )

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.tintColor = UIColor.white.withAlphaComponent(0.35)
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72, weight: .light)
        addSubview(symbolImageView)

        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false
        let textStackView = UIStackView(axis: .vertical, spacing: 4, alignment: .leading, arrangedSubviews: [eyebrowLabel, headlineLabel])
        addSubview(textStackView)

        NSLayoutConstraint.activate([
            symbolImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            symbolImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            textStackView.trailingAnchor.constraint(lessThanOrEqualTo: symbolImageView.leadingAnchor, constant: -12),
            textStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with hero: SocialHero) {
        gradientLayer.colors = hero.gradient.map(\.color.cgColor)
        symbolImageView.image = UIImage(systemName: hero.symbolName)
        eyebrowLabel.attributedText = NSAttributedString(string: hero.eyebrow.uppercased(), attributes: [
            .font: UIFont.preferredFont(forTextStyle: .caption2).withWeight(.bold),
            .kern: 2,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
        ])
        headlineLabel.text = hero.headline
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
}
