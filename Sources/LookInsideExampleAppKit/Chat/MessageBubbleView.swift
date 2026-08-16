import AppKit

/// One chat bubble: avatar plus payload, aligned left for incoming messages
/// and right for outgoing ones.
final class MessageBubbleView: NSView {
    private let timestampLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption2),
        color: DemoPalette.secondaryLabel,
        alignment: .center
    )
    private let avatarBadgeView: AvatarBadgeView
    private let bubbleContainerView = NSView()

    init(message: ChatMessage, conversation: Conversation, showsAvatar: Bool, showsTimestamp: Bool) {
        avatarBadgeView = AvatarBadgeView(
            initials: conversation.initials,
            tint: conversation.tint,
            diameter: 26
        )
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        timestampLabel.stringValue = showsTimestamp ? message.timeLabel : ""
        timestampLabel.isHidden = !showsTimestamp
        avatarBadgeView.isHidden = message.isFromMe
        avatarBadgeView.alphaValue = showsAvatar ? 1 : 0

        bubbleContainerView.translatesAutoresizingMaskIntoConstraints = false
        bubbleContainerView.addSubview(makePayloadView(for: message))

        addSubview(timestampLabel)
        addSubview(avatarBadgeView)
        addSubview(bubbleContainerView)

        if let payloadView = bubbleContainerView.subviews.first {
            payloadView.pinEdges(to: bubbleContainerView)
        }

        var constraints: [NSLayoutConstraint] = [
            timestampLabel.topAnchor.constraint(equalTo: topAnchor),
            timestampLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            bubbleContainerView.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: showsTimestamp ? 6 : 0),
            bubbleContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            avatarBadgeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarBadgeView.bottomAnchor.constraint(equalTo: bubbleContainerView.bottomAnchor),
        ]

        if message.isFromMe {
            constraints += [
                bubbleContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bubbleContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 64),
            ]
        } else {
            constraints += [
                bubbleContainerView.leadingAnchor.constraint(equalTo: avatarBadgeView.trailingAnchor, constant: 8),
                bubbleContainerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -64),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makePayloadView(for message: ChatMessage) -> NSView {
        switch message.kind {
        case let .text(body):
            makeTextBubble(body: body, isFromMe: message.isFromMe)
        case let .image(symbolName, tint):
            makeImageBubble(symbolName: symbolName, tint: tint)
        case let .audio(duration):
            makeAudioBubble(duration: duration, isFromMe: message.isFromMe)
        }
    }

    private func makeTextBubble(body: String, isFromMe: Bool) -> NSView {
        let bubbleBoxView = makeBubbleBackground(isFromMe: isFromMe)
        let bodyLabel = NSTextField.demoLabel(
            body,
            font: .preferredFont(forTextStyle: .body),
            color: isFromMe ? .white : DemoPalette.primaryLabel,
            maximumNumberOfLines: 0
        )
        bubbleBoxView.contentView?.addSubview(bodyLabel)
        if let bubbleContentView = bubbleBoxView.contentView {
            bodyLabel.pinEdges(
                to: bubbleContentView,
                insets: NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            )
        }
        bodyLabel.preferredMaxLayoutWidth = 420
        return bubbleBoxView
    }

    private func makeImageBubble(symbolName: String, tint: DemoTint) -> NSView {
        let imageBubbleView = GradientView(cornerRadius: DemoMetrics.bubbleCornerRadius)
        imageBubbleView.setColors([
            tint.color.withAlphaComponent(0.85),
            tint.color.withAlphaComponent(0.45),
        ])

        let symbolImageView = NSImageView()
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.image = NSImage.demoSymbol(symbolName, pointSize: 26, weight: .light)
        symbolImageView.contentTintColor = .white
        imageBubbleView.addSubview(symbolImageView)

        NSLayoutConstraint.activate([
            imageBubbleView.widthAnchor.constraint(equalToConstant: 160),
            imageBubbleView.heightAnchor.constraint(equalToConstant: 110),
            symbolImageView.centerXAnchor.constraint(equalTo: imageBubbleView.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: imageBubbleView.centerYAnchor),
        ])
        return imageBubbleView
    }

    private func makeAudioBubble(duration: TimeInterval, isFromMe: Bool) -> NSView {
        let bubbleBoxView = makeBubbleBackground(isFromMe: isFromMe)
        let foregroundColor: NSColor = isFromMe ? .white : DemoPalette.primaryLabel

        let playImageView = NSImageView()
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        playImageView.image = NSImage.demoSymbol("play.fill", pointSize: 11)
        playImageView.contentTintColor = foregroundColor

        let waveformView = WaveformView(barColor: foregroundColor)

        let durationLabel = NSTextField.demoLabel(
            DemoDurationFormatter.minuteSecond(duration),
            font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            color: foregroundColor
        )

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [playImageView, waveformView, durationLabel]
        )
        bubbleBoxView.contentView?.addSubview(rowStackView)
        if let bubbleContentView = bubbleBoxView.contentView {
            rowStackView.pinEdges(
                to: bubbleContentView,
                insets: NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            )
        }
        return bubbleBoxView
    }

    private func makeBubbleBackground(isFromMe: Bool) -> NSBox {
        CardBoxView(
            cornerRadius: DemoMetrics.bubbleCornerRadius,
            fillColor: isFromMe ? DemoPalette.accent : DemoPalette.cardBackground
        )
    }
}

/// The 18-bar waveform inside a voice-note bubble.
final class WaveformView: NSView {
    private static let barHeights: [CGFloat] = [6, 10, 18, 12, 22, 16, 8, 14, 20, 10, 6, 18, 24, 12, 8, 16, 12, 8]

    init(barColor: NSColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let barViews: [NSView] = Self.barHeights.map { barHeight in
            let barBoxView = CardBoxView(cornerRadius: 1, fillColor: barColor)
            barBoxView.widthAnchor.constraint(equalToConstant: 2).isActive = true
            barBoxView.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
            return barBoxView
        }

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 2,
            alignment: .centerY,
            views: barViews
        )
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
