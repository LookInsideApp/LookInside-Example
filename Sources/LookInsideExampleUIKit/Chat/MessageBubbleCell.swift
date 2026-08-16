import UIKit

/// One chat bubble.
///
/// Incoming and outgoing layouts are two constraint sets toggled on the same
/// subview tree, and the three payload kinds (text, image, voice note) are
/// three sibling views shown one at a time — so the cell keeps a stable
/// hierarchy across reuse instead of rebuilding itself per message.
final class MessageBubbleCell: UITableViewCell {
    static let reuseIdentifier = "MessageBubbleCell"

    private let timestampLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption2), color: DemoPalette.secondaryLabel, alignment: .center)
    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 28)
    private let bubbleBackgroundView = UIView()
    private let bubbleGradientLayer = CAGradientLayer()
    private let bubbleContentStackView = UIStackView(axis: .vertical)

    private let messageTextLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .body), color: DemoPalette.primaryLabel, numberOfLines: 0)
    private let imageContentView = UIView()
    private let imageGradientLayer = CAGradientLayer()
    private let imageSymbolImageView = UIImageView()
    private let audioContentStackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center)
    private let audioPlayImageView = UIImageView(image: UIImage(systemName: "play.fill"))
    private let audioWaveformStackView = UIStackView(axis: .horizontal, spacing: 2, alignment: .center)
    private let audioDurationLabel = UILabel(text: nil, font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular), color: DemoPalette.primaryLabel)

    private var incomingConstraints: [NSLayoutConstraint] = []
    private var outgoingConstraints: [NSLayoutConstraint] = []

    private static let waveformBarHeights: [CGFloat] = [6, 10, 18, 12, 22, 16, 8, 14, 20, 10, 6, 18, 24, 12, 8, 16, 12, 8]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timestampLabel)
        contentView.addSubview(avatarBadgeView)

        buildBubble()
        buildImageContent()
        buildAudioContent()

        bubbleContentStackView.addArrangedSubview(messageTextLabel)
        bubbleContentStackView.addArrangedSubview(imageContentView)
        bubbleContentStackView.addArrangedSubview(audioContentStackView)

        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            bubbleBackgroundView.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 4),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            avatarBadgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarBadgeView.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor),
        ])

        incomingConstraints = [
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: avatarBadgeView.trailingAnchor, constant: 8),
            bubbleBackgroundView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56),
        ]
        outgoingConstraints = [
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 56),
        ]
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildBubble() {
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.layer.cornerRadius = DemoMetrics.bubbleCornerRadius
        bubbleBackgroundView.layer.cornerCurve = .continuous
        bubbleBackgroundView.layer.masksToBounds = true
        bubbleGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bubbleGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        bubbleBackgroundView.layer.insertSublayer(bubbleGradientLayer, at: 0)
        contentView.addSubview(bubbleBackgroundView)

        bubbleContentStackView.isLayoutMarginsRelativeArrangement = true
        bubbleBackgroundView.addSubview(bubbleContentStackView)
        bubbleContentStackView.pinEdges(to: bubbleBackgroundView)
    }

    private func buildImageContent() {
        imageContentView.translatesAutoresizingMaskIntoConstraints = false
        imageGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        imageGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        imageContentView.layer.addSublayer(imageGradientLayer)

        imageSymbolImageView.translatesAutoresizingMaskIntoConstraints = false
        imageSymbolImageView.tintColor = .white
        imageSymbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .light)
        imageSymbolImageView.contentMode = .center
        imageContentView.addSubview(imageSymbolImageView)

        NSLayoutConstraint.activate([
            imageContentView.widthAnchor.constraint(equalToConstant: 160),
            imageContentView.heightAnchor.constraint(equalToConstant: 110),
            imageSymbolImageView.centerXAnchor.constraint(equalTo: imageContentView.centerXAnchor),
            imageSymbolImageView.centerYAnchor.constraint(equalTo: imageContentView.centerYAnchor),
        ])
    }

    private func buildAudioContent() {
        audioPlayImageView.translatesAutoresizingMaskIntoConstraints = false
        audioPlayImageView.contentMode = .scaleAspectFit

        for barHeight in Self.waveformBarHeights {
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            barView.layer.cornerRadius = 1
            NSLayoutConstraint.activate([
                barView.widthAnchor.constraint(equalToConstant: 2),
                barView.heightAnchor.constraint(equalToConstant: barHeight),
            ])
            audioWaveformStackView.addArrangedSubview(barView)
        }

        audioContentStackView.addArrangedSubview(audioPlayImageView)
        audioContentStackView.addArrangedSubview(audioWaveformStackView)
        audioContentStackView.addArrangedSubview(audioDurationLabel)
    }

    func configure(message: ChatMessage, conversation: Conversation, showsAvatar: Bool, showsTimestamp: Bool) {
        // Clearing the text (not just hiding) collapses the label's intrinsic
        // height, so a bubble without a timestamp does not reserve a blank row.
        timestampLabel.text = showsTimestamp ? message.timeLabel : nil
        timestampLabel.isHidden = !showsTimestamp

        avatarBadgeView.configure(initials: conversation.initials, tint: conversation.tint)
        avatarBadgeView.alpha = (message.isFromMe || !showsAvatar) ? 0 : 1

        NSLayoutConstraint.deactivate(incomingConstraints + outgoingConstraints)
        NSLayoutConstraint.activate(message.isFromMe ? outgoingConstraints : incomingConstraints)

        let foregroundColor: UIColor = message.isFromMe ? .white : DemoPalette.primaryLabel
        messageTextLabel.textColor = foregroundColor
        audioDurationLabel.textColor = foregroundColor
        audioPlayImageView.tintColor = foregroundColor
        for barView in audioWaveformStackView.arrangedSubviews {
            barView.backgroundColor = foregroundColor
        }

        switch message.kind {
        case let .text(body):
            messageTextLabel.text = body
            messageTextLabel.isHidden = false
            imageContentView.isHidden = true
            audioContentStackView.isHidden = true
            bubbleContentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
            applyBubbleBackground(isFromMe: message.isFromMe, isTransparent: false)

        case let .image(symbolName, tint):
            imageSymbolImageView.image = UIImage(systemName: symbolName)
            imageGradientLayer.colors = [
                tint.color.withAlphaComponent(0.85).cgColor,
                tint.color.withAlphaComponent(0.45).cgColor,
            ]
            messageTextLabel.isHidden = true
            imageContentView.isHidden = false
            audioContentStackView.isHidden = true
            bubbleContentStackView.directionalLayoutMargins = .zero
            applyBubbleBackground(isFromMe: message.isFromMe, isTransparent: true)

        case let .audio(duration):
            audioDurationLabel.text = DemoDurationFormatter.minuteSecond(duration)
            messageTextLabel.isHidden = true
            imageContentView.isHidden = true
            audioContentStackView.isHidden = false
            bubbleContentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            applyBubbleBackground(isFromMe: message.isFromMe, isTransparent: false)
        }

        setNeedsLayout()
    }

    private func applyBubbleBackground(isFromMe: Bool, isTransparent: Bool) {
        if isTransparent {
            bubbleGradientLayer.isHidden = true
            bubbleBackgroundView.backgroundColor = .clear
        } else if isFromMe {
            bubbleGradientLayer.isHidden = false
            bubbleGradientLayer.colors = [
                DemoPalette.accent.cgColor,
                DemoPalette.accent.withAlphaComponent(0.78).cgColor,
            ]
            bubbleBackgroundView.backgroundColor = .clear
        } else {
            bubbleGradientLayer.isHidden = true
            bubbleBackgroundView.backgroundColor = DemoPalette.cardBackground
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleGradientLayer.frame = bubbleBackgroundView.bounds
        imageGradientLayer.frame = imageContentView.bounds
    }
}
