import UIKit

/// The 240×240 "now playing" artwork.
///
/// Everything here is Core Animation: a gradient fill, three concentric stroked
/// rings, an SF Symbol image view and a drop shadow driven from the layer. It is
/// the densest layer tree in the UIKit example, which makes it a good target for
/// inspecting layer geometry and animations from the LookInside host.
final class AlbumArtworkView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let ringLayers: [CAShapeLayer] = (0 ..< 3).map { _ in CAShapeLayer() }
    private let symbolImageView = UIImageView()
    private let albumLabel = UILabel()

    private static let pulseAnimationKey = "artworkPulse"

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.masksToBounds = false
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 28
        gradientLayer.cornerCurve = .continuous
        gradientLayer.masksToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)

        for ringLayer in ringLayers {
            ringLayer.fillColor = UIColor.clear.cgColor
            ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
            ringLayer.lineWidth = 1
            gradientLayer.addSublayer(ringLayer)
        }

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.tintColor = .white
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 64, weight: .light)
        symbolImageView.layer.shadowColor = UIColor.black.cgColor
        symbolImageView.layer.shadowOpacity = 0.25
        symbolImageView.layer.shadowRadius = 8
        symbolImageView.layer.shadowOffset = CGSize(width: 0, height: 6)

        albumLabel.translatesAutoresizingMaskIntoConstraints = false
        albumLabel.textAlignment = .center
        albumLabel.textColor = UIColor.white.withAlphaComponent(0.85)

        let contentStackView = UIStackView(
            axis: .vertical,
            spacing: 14,
            alignment: .center,
            arrangedSubviews: [symbolImageView, albumLabel]
        )
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            symbolImageView.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with track: MusicTrack) {
        let baseColor = track.tint.color
        gradientLayer.colors = [
            baseColor.withAlphaComponent(0.95).cgColor,
            baseColor.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.45).cgColor,
        ]
        symbolImageView.image = UIImage(systemName: track.symbolName)
        albumLabel.attributedText = NSAttributedString(
            string: track.album.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .kern: 2,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            ]
        )

        layer.shadowColor = baseColor.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 16)
    }

    func setPulsing(_ isPulsing: Bool) {
        if isPulsing {
            guard symbolImageView.layer.animation(forKey: Self.pulseAnimationKey) == nil else { return }
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.fromValue = 0.98
            pulseAnimation.toValue = 1.04
            pulseAnimation.duration = 1.6
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .greatestFiniteMagnitude
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            symbolImageView.layer.add(pulseAnimation, forKey: Self.pulseAnimationKey)
        } else {
            symbolImageView.layer.removeAnimation(forKey: Self.pulseAnimationKey)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for (ringIndex, ringLayer) in ringLayers.enumerated() {
            let diameter = CGFloat(120 + ringIndex * 60)
            let ringRect = CGRect(
                x: center.x - diameter / 2,
                y: center.y - diameter / 2,
                width: diameter,
                height: diameter
            )
            ringLayer.frame = bounds
            ringLayer.path = UIBezierPath(ovalIn: ringRect).cgPath
        }
    }
}
