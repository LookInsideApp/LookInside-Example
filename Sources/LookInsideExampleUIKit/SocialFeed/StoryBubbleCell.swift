import UIKit

/// A story avatar. Unseen stories get a conic gradient ring drawn with a
/// `CAGradientLayer` masked by a stroked `CAShapeLayer` — the UIKit equivalent
/// of SwiftUI's `AngularGradient` stroke border.
final class StoryBubbleCell: UICollectionViewCell {
    static let reuseIdentifier = "StoryBubbleCell"

    private let ringGradientLayer = CAGradientLayer()
    private let ringMaskLayer = CAShapeLayer()
    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 60)
    private let nameLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption2), color: DemoPalette.primaryLabel, alignment: .center)

    private var isUnseen = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        ringGradientLayer.type = .conic
        ringGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        ringGradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        ringGradientLayer.colors = [
            UIColor.systemPink.cgColor,
            UIColor.systemOrange.cgColor,
            UIColor.systemYellow.cgColor,
            UIColor.systemPink.cgColor,
        ]
        ringMaskLayer.fillColor = UIColor.clear.cgColor
        ringMaskLayer.strokeColor = UIColor.black.cgColor
        ringMaskLayer.lineWidth = 2.5
        ringGradientLayer.mask = ringMaskLayer

        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.layer.addSublayer(ringGradientLayer)
        avatarContainer.addSubview(avatarBadgeView)

        let columnStackView = UIStackView(
            axis: .vertical,
            spacing: 8,
            alignment: .center,
            arrangedSubviews: [avatarContainer, nameLabel]
        )
        contentView.addSubview(columnStackView)
        columnStackView.pinEdges(to: contentView)

        NSLayoutConstraint.activate([
            avatarContainer.widthAnchor.constraint(equalToConstant: 70),
            avatarContainer.heightAnchor.constraint(equalToConstant: 70),
            avatarBadgeView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarBadgeView.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 64),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with story: SocialStory) {
        isUnseen = story.isUnseen
        avatarBadgeView.configure(initials: story.initials, tint: story.tint)
        avatarBadgeView.diameter = story.isUnseen ? 60 : 64
        nameLabel.text = story.name
        ringGradientLayer.isHidden = !story.isUnseen
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let avatarContainer = avatarBadgeView.superview else { return }
        ringGradientLayer.frame = avatarContainer.bounds
        let inset = ringMaskLayer.lineWidth / 2
        ringMaskLayer.frame = avatarContainer.bounds
        ringMaskLayer.path = UIBezierPath(ovalIn: avatarContainer.bounds.insetBy(dx: inset, dy: inset)).cgPath
    }
}

/// The dashed "Your story" bubble that opens the (non-functional) composer.
final class AddStoryCell: UICollectionViewCell {
    static let reuseIdentifier = "AddStoryCell"

    private let dashedBorderLayer = CAShapeLayer()
    private let circleView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = DemoPalette.cardBackground

        dashedBorderLayer.fillColor = UIColor.clear.cgColor
        dashedBorderLayer.strokeColor = DemoPalette.accent.withAlphaComponent(0.4).cgColor
        dashedBorderLayer.lineWidth = 2
        dashedBorderLayer.lineDashPattern = [3, 3]
        circleView.layer.addSublayer(dashedBorderLayer)

        let plusImageView = UIImageView(image: UIImage(systemName: "plus"))
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        plusImageView.tintColor = DemoPalette.accent
        plusImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title2)
        circleView.addSubview(plusImageView)

        let titleLabel = UILabel(text: "Your story", font: .preferredFont(forTextStyle: .caption2), color: DemoPalette.secondaryLabel, alignment: .center)

        let columnStackView = UIStackView(
            axis: .vertical,
            spacing: 8,
            alignment: .center,
            arrangedSubviews: [circleView, titleLabel]
        )
        contentView.addSubview(columnStackView)
        columnStackView.pinEdges(to: contentView)

        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalToConstant: 64),
            circleView.heightAnchor.constraint(equalToConstant: 64),
            plusImageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            plusImageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.height / 2
        dashedBorderLayer.frame = circleView.bounds
        dashedBorderLayer.path = UIBezierPath(ovalIn: circleView.bounds.insetBy(dx: 1, dy: 1)).cgPath
    }
}
