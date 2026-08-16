import AppKit

/// The 240×240 "now playing" artwork: a gradient, three concentric stroked
/// rings and a pulsing SF Symbol, all in Core Animation sublayers.
final class AlbumArtworkView: GradientView {
    private let ringLayers: [CAShapeLayer] = (0 ..< 3).map { _ in CAShapeLayer() }
    private let symbolImageView = NSImageView()
    private let albumLabel = NSTextField.demoLabel(
        font: .systemFont(ofSize: 11, weight: .semibold),
        color: .white,
        alignment: .center
    )

    private static let pulseAnimationKey = "artworkPulse"

    init() {
        super.init(cornerRadius: 28)

        gradientLayer.borderWidth = 1
        gradientLayer.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor

        for ringLayer in ringLayers {
            ringLayer.fillColor = NSColor.clear.cgColor
            ringLayer.strokeColor = NSColor.white.withAlphaComponent(0.12).cgColor
            ringLayer.lineWidth = 1
            gradientLayer.addSublayer(ringLayer)
        }

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.imageScaling = .scaleProportionallyUpOrDown
        symbolImageView.contentTintColor = .white
        symbolImageView.wantsLayer = true

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 14,
            alignment: .centerX,
            views: [symbolImageView, albumLabel]
        )
        addSubview(columnStackView)

        NSLayoutConstraint.activate([
            columnStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            columnStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            columnStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            symbolImageView.widthAnchor.constraint(equalToConstant: 76),
            symbolImageView.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    func configure(with track: MusicTrack) {
        setColors([
            track.tint.color.withAlphaComponent(0.95),
            track.tint.color.withAlphaComponent(0.55),
            NSColor.black.withAlphaComponent(0.45),
        ])
        symbolImageView.image = NSImage.demoSymbol(track.symbolName, pointSize: 64, weight: .light)
        albumLabel.attributedStringValue = NSAttributedString(
            string: track.album.uppercased(),
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .kern: 2,
                .foregroundColor: NSColor.white.withAlphaComponent(0.85),
            ]
        )

        // Shadows belong to the view, not the layer: AppKit recomputes
        // `layer.shadow*` from `NSView.shadow` on every property sync.
        let dropShadow = NSShadow()
        dropShadow.shadowColor = track.tint.color.withAlphaComponent(0.45)
        dropShadow.shadowBlurRadius = 24
        dropShadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow = dropShadow
    }

    func setPulsing(_ isPulsing: Bool) {
        guard let symbolLayer = symbolImageView.layer else { return }
        if isPulsing {
            guard symbolLayer.animation(forKey: Self.pulseAnimationKey) == nil else { return }
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.fromValue = 0.98
            pulseAnimation.toValue = 1.04
            pulseAnimation.duration = 1.6
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .greatestFiniteMagnitude
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            symbolLayer.add(pulseAnimation, forKey: Self.pulseAnimationKey)
        } else {
            symbolLayer.removeAnimation(forKey: Self.pulseAnimationKey)
        }
    }

    override func layoutGradientSublayers() {
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
            ringLayer.path = CGPath(ellipseIn: ringRect, transform: nil)
        }
    }
}
