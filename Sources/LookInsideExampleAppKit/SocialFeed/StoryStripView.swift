import AppKit

/// One story avatar. Unseen stories are ringed with a conic gradient masked by
/// a stroked shape layer.
final class StoryBubbleView: NSView {
    private let ringHostView = NSView()
    private let ringGradientLayer = CAGradientLayer()
    private let ringMaskLayer = CAShapeLayer()
    private let avatarBadgeView: AvatarBadgeView
    private let nameLabel: NSTextField

    init(story: SocialStory) {
        avatarBadgeView = AvatarBadgeView(
            initials: story.initials,
            tint: story.tint,
            diameter: story.isUnseen ? 56 : 60
        )
        nameLabel = NSTextField.demoLabel(
            story.name,
            font: .preferredFont(forTextStyle: .caption1),
            color: DemoPalette.primaryLabel,
            alignment: .center
        )
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        ringHostView.translatesAutoresizingMaskIntoConstraints = false
        ringHostView.wantsLayer = true
        ringGradientLayer.type = .conic
        ringGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        ringGradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        ringGradientLayer.colors = [
            NSColor.systemPink.cgColor,
            NSColor.systemOrange.cgColor,
            NSColor.systemYellow.cgColor,
            NSColor.systemPink.cgColor,
        ]
        ringMaskLayer.fillColor = NSColor.clear.cgColor
        ringMaskLayer.strokeColor = NSColor.black.cgColor
        ringMaskLayer.lineWidth = 2.5
        ringGradientLayer.mask = ringMaskLayer
        ringGradientLayer.isHidden = !story.isUnseen
        ringHostView.layer?.addSublayer(ringGradientLayer)
        ringHostView.addSubview(avatarBadgeView)

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 8,
            alignment: .centerX,
            views: [ringHostView, nameLabel]
        )
        addSubview(columnStackView)
        columnStackView.pinEdges(to: self)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 68),
            ringHostView.widthAnchor.constraint(equalToConstant: 66),
            ringHostView.heightAnchor.constraint(equalToConstant: 66),
            avatarBadgeView.centerXAnchor.constraint(equalTo: ringHostView.centerXAnchor),
            avatarBadgeView.centerYAnchor.constraint(equalTo: ringHostView.centerYAnchor),
            nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 66),
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
        ringGradientLayer.frame = ringHostView.bounds
        ringMaskLayer.frame = ringHostView.bounds
        let inset = ringMaskLayer.lineWidth / 2
        ringMaskLayer.path = CGPath(
            ellipseIn: ringHostView.bounds.insetBy(dx: inset, dy: inset),
            transform: nil
        )
        CATransaction.commit()
    }
}

/// The dashed "Your story" bubble.
final class AddStoryBubbleView: NSView {
    private let circleHostView = NSView()
    private let circleFillLayer = CALayer()
    private let dashedBorderLayer = CAShapeLayer()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        circleHostView.translatesAutoresizingMaskIntoConstraints = false
        circleHostView.wantsLayer = true
        circleFillLayer.backgroundColor = DemoPalette.cardBackground.cgColor
        dashedBorderLayer.fillColor = NSColor.clear.cgColor
        dashedBorderLayer.strokeColor = DemoPalette.accent.withAlphaComponent(0.4).cgColor
        dashedBorderLayer.lineWidth = 2
        dashedBorderLayer.lineDashPattern = [3, 3]
        circleHostView.layer?.addSublayer(circleFillLayer)
        circleHostView.layer?.addSublayer(dashedBorderLayer)

        let plusImageView = NSImageView()
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        plusImageView.image = NSImage.demoSymbol("plus", pointSize: 18, weight: .semibold)
        plusImageView.contentTintColor = DemoPalette.accent
        circleHostView.addSubview(plusImageView)

        let titleLabel = NSTextField.demoLabel(
            "Your story",
            font: .preferredFont(forTextStyle: .caption1),
            color: DemoPalette.secondaryLabel,
            alignment: .center
        )

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 8,
            alignment: .centerX,
            views: [circleHostView, titleLabel]
        )
        addSubview(columnStackView)
        columnStackView.pinEdges(to: self)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 68),
            circleHostView.widthAnchor.constraint(equalToConstant: 60),
            circleHostView.heightAnchor.constraint(equalToConstant: 60),
            plusImageView.centerXAnchor.constraint(equalTo: circleHostView.centerXAnchor),
            plusImageView.centerYAnchor.constraint(equalTo: circleHostView.centerYAnchor),
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
        circleFillLayer.frame = circleHostView.bounds
        circleFillLayer.cornerRadius = circleHostView.bounds.height / 2
        dashedBorderLayer.frame = circleHostView.bounds
        dashedBorderLayer.path = CGPath(
            ellipseIn: circleHostView.bounds.insetBy(dx: 1, dy: 1),
            transform: nil
        )
        CATransaction.commit()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            circleFillLayer.backgroundColor = DemoPalette.cardBackground.cgColor
            dashedBorderLayer.strokeColor = DemoPalette.accent.withAlphaComponent(0.4).cgColor
        }
    }
}

/// The horizontally scrolling strip of stories above the feed.
final class StoryStripView: NSView {
    init(stories: [SocialStory]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.horizontalScrollElasticity = .allowed

        let bubbleViews: [NSView] = [AddStoryBubbleView()] + stories.map { StoryBubbleView(story: $0) }
        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 14,
            alignment: .top,
            views: bubbleViews
        )

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(rowStackView)
        rowStackView.pinEdges(to: documentView)
        scrollView.documentView = documentView

        addSubview(scrollView)
        scrollView.pinEdges(to: self, insets: NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))

        NSLayoutConstraint.activate([
            documentView.heightAnchor.constraint(equalTo: scrollView.contentView.heightAnchor),
            heightAnchor.constraint(equalToConstant: 116),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
