import UIKit

/// A circular gradient badge with monogram initials.
///
/// A plain `UIView` subclass driving a `CAGradientLayer` directly, so the
/// layer tree LookInside walks stays hand-authored.
final class AvatarBadgeView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let initialsLabel = UILabel()

    init(diameter: CGFloat) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(gradientLayer)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        layer.masksToBounds = true

        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.textColor = .white
        initialsLabel.textAlignment = .center
        initialsLabel.font = .systemFont(ofSize: diameter * 0.4, weight: .bold)
        addSubview(initialsLabel)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(initials: String, tint: DemoTint) {
        initialsLabel.text = initials
        let baseColor = tint.color
        gradientLayer.colors = [
            baseColor.withAlphaComponent(0.9).cgColor,
            baseColor.withAlphaComponent(0.55).cgColor,
        ]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        layer.cornerRadius = bounds.height / 2
    }
}
