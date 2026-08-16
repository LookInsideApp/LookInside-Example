import AppKit

/// A 168-point tile in the horizontally scrolling "Made for you" strip.
final class PlaylistCardView: NSView {
    private let artworkView = GradientView(cornerRadius: 14)
    private let symbolImageView = NSImageView()
    private let subtitleLabel = NSTextField.demoLabel(
        font: .systemFont(ofSize: 11, weight: .semibold),
        color: .white
    )
    private let nameLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body).withWeight(.semibold),
        color: DemoPalette.primaryLabel,
        maximumNumberOfLines: 2
    )
    private let detailLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption2),
        color: DemoPalette.secondaryLabel
    )

    init(playlist: Playlist) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.contentTintColor = NSColor.white.withAlphaComponent(0.9)
        symbolImageView.imageScaling = .scaleProportionallyDown

        let overlayStackView = NSStackView(
            orientation: .vertical,
            spacing: 4,
            alignment: .leading,
            views: [symbolImageView, subtitleLabel]
        )
        artworkView.addSubview(overlayStackView)

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 8,
            alignment: .leading,
            views: [artworkView, nameLabel, detailLabel]
        )
        columnStackView.setCustomSpacing(2, after: nameLabel)
        addSubview(columnStackView)
        columnStackView.pinEdges(to: self)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 168),
            artworkView.widthAnchor.constraint(equalToConstant: 168),
            artworkView.heightAnchor.constraint(equalToConstant: 168),
            nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 168),
            overlayStackView.leadingAnchor.constraint(equalTo: artworkView.leadingAnchor, constant: 14),
            overlayStackView.trailingAnchor.constraint(lessThanOrEqualTo: artworkView.trailingAnchor, constant: -14),
            overlayStackView.bottomAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: -14),
            symbolImageView.heightAnchor.constraint(equalToConstant: 20),
        ])

        configure(with: playlist)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(with playlist: Playlist) {
        artworkView.setColors([
            playlist.tint.color,
            playlist.tint.color.withAlphaComponent(0.6),
        ])
        symbolImageView.image = NSImage.demoSymbol(playlist.symbolName, pointSize: 18)
        subtitleLabel.attributedStringValue = NSAttributedString(
            string: playlist.subtitle,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .kern: 1.4,
                .foregroundColor: NSColor.white.withAlphaComponent(0.85),
            ]
        )
        nameLabel.stringValue = playlist.name
        detailLabel.stringValue = "\(playlist.trackCount) tracks · \(playlist.durationInMinutes) min"
    }
}
