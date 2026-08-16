import AppKit

/// Circular gradient badge with monogram initials, the AppKit twin of the
/// UIKit example's `AvatarBadgeView`.
final class AvatarBadgeView: GradientView {
    private let initialsLabel = NSTextField.demoLabel(
        font: .systemFont(ofSize: 18, weight: .bold),
        color: .white,
        alignment: .center
    )

    private lazy var diameterConstraint = widthAnchor.constraint(equalToConstant: diameter)

    var diameter: CGFloat {
        didSet {
            guard diameter != oldValue else { return }
            diameterConstraint.constant = diameter
            initialsLabel.font = .systemFont(ofSize: diameter * 0.42, weight: .bold)
            cornerRadius = diameter / 2
        }
    }

    init(initials: String, tint: DemoTint, diameter: CGFloat = 44) {
        self.diameter = diameter
        super.init(cornerRadius: diameter / 2)

        addSubview(initialsLabel)
        NSLayoutConstraint.activate([
            diameterConstraint,
            heightAnchor.constraint(equalTo: widthAnchor),
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            initialsLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9),
        ])

        initialsLabel.font = .systemFont(ofSize: diameter * 0.42, weight: .bold)
        configure(initials: initials, tint: tint)
    }

    func configure(initials: String, tint: DemoTint) {
        initialsLabel.stringValue = initials
        setColors([
            tint.color.withAlphaComponent(0.85),
            tint.color.withAlphaComponent(0.55),
        ])
    }
}

/// The small green dot marking an online contact.
final class OnlineIndicatorView: NSView {
    private let dotLayer = CALayer()
    private let ringLayer = CALayer()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        ringLayer.backgroundColor = DemoPalette.cardBackground.cgColor
        dotLayer.backgroundColor = NSColor.systemGreen.cgColor
        layer?.addSublayer(ringLayer)
        layer?.addSublayer(dotLayer)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 12),
            heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ringLayer.frame = bounds
        ringLayer.cornerRadius = bounds.height / 2
        dotLayer.frame = bounds.insetBy(dx: 2, dy: 2)
        dotLayer.cornerRadius = dotLayer.bounds.height / 2
        CATransaction.commit()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            ringLayer.backgroundColor = DemoPalette.cardBackground.cgColor
            dotLayer.backgroundColor = NSColor.systemGreen.cgColor
        }
    }
}
