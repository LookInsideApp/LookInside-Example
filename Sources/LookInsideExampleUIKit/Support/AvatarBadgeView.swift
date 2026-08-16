import UIKit

/// A circular gradient badge with monogram initials.
///
/// Written as a plain `UIView` subclass driving a `CAGradientLayer` directly,
/// so the layer tree that LookInside walks stays hand-authored rather than
/// synthesised by a higher-level framework.
final class AvatarBadgeView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let initialsLabel = UILabel()

    var diameter: CGFloat {
        didSet {
            guard diameter != oldValue else { return }
            diameterConstraint.constant = diameter
            initialsLabel.font = .systemFont(ofSize: diameter * 0.42, weight: .bold)
            setNeedsLayout()
        }
    }

    private lazy var diameterConstraint = widthAnchor.constraint(equalToConstant: diameter)

    init(initials: String, tint: DemoTint, diameter: CGFloat = 44) {
        self.diameter = diameter
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(gradientLayer)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        layer.masksToBounds = true

        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.textColor = .white
        initialsLabel.textAlignment = .center
        initialsLabel.adjustsFontSizeToFitWidth = true
        initialsLabel.minimumScaleFactor = 0.6
        addSubview(initialsLabel)

        NSLayoutConstraint.activate([
            diameterConstraint,
            heightAnchor.constraint(equalTo: widthAnchor),
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            initialsLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9),
        ])

        configure(initials: initials, tint: tint)
        initialsLabel.font = .systemFont(ofSize: diameter * 0.42, weight: .bold)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(initials: String, tint: DemoTint) {
        initialsLabel.text = initials
        let baseColor = tint.color
        gradientLayer.colors = [
            baseColor.withAlphaComponent(0.85).cgColor,
            baseColor.withAlphaComponent(0.55).cgColor,
        ]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        layer.cornerRadius = bounds.height / 2
    }
}

/// The small green dot that marks an online contact.
final class OnlineIndicatorView: UIView {
    init(ringColor: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemGreen
        layer.borderWidth = 2
        layer.borderColor = ringColor.cgColor
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 12),
            heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
