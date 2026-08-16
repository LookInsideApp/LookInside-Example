import AppKit

/// One row of the "Up Next" card, clickable via a gesture recogniser.
final class QueueRowView: NSView {
    private let artworkView = GradientView(cornerRadius: 8)
    private let artworkSymbolImageView = NSImageView()
    private let titleLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body).withWeight(.semibold),
        color: DemoPalette.primaryLabel
    )
    private let artistLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption1),
        color: DemoPalette.secondaryLabel
    )
    private let durationLabel = NSTextField.demoLabel(
        font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        color: DemoPalette.tertiaryLabel,
        alignment: .right
    )
    private let nowPlayingImageView = NSImageView()

    private let onSelect: () -> Void

    init(track: MusicTrack, isCurrent: Bool, onSelect: @escaping () -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        artworkSymbolImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkSymbolImageView.contentTintColor = .white
        artworkSymbolImageView.imageScaling = .scaleProportionallyDown
        artworkView.addSubview(artworkSymbolImageView)

        nowPlayingImageView.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingImageView.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)
        nowPlayingImageView.imageScaling = .scaleProportionallyDown

        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 2,
            alignment: .leading,
            views: [titleLabel, artistLabel]
        )

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 12,
            alignment: .centerY,
            views: [artworkView, textColumnStackView, NSView.flexibleSpacer(), durationLabel, nowPlayingImageView]
        )
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self, insets: NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))

        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 40),
            artworkView.heightAnchor.constraint(equalToConstant: 40),
            artworkSymbolImageView.centerXAnchor.constraint(equalTo: artworkView.centerXAnchor),
            artworkSymbolImageView.centerYAnchor.constraint(equalTo: artworkView.centerYAnchor),
            nowPlayingImageView.widthAnchor.constraint(equalToConstant: 16),
        ])

        configure(track: track, isCurrent: isCurrent)
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleClick)))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(track: MusicTrack, isCurrent: Bool) {
        artworkView.setColors([
            track.tint.color,
            track.tint.color.withAlphaComponent(0.6),
        ])
        artworkSymbolImageView.image = NSImage.demoSymbol(track.symbolName, pointSize: 15)
        titleLabel.stringValue = track.title
        artistLabel.stringValue = track.artist
        durationLabel.stringValue = DemoDurationFormatter.minuteSecond(track.duration)
        durationLabel.isHidden = isCurrent
        nowPlayingImageView.isHidden = !isCurrent
        nowPlayingImageView.contentTintColor = track.tint.color
    }

    @objc
    private func handleClick() {
        onSelect()
    }
}
