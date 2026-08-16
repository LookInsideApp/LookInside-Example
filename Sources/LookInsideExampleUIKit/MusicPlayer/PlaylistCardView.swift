import UIKit

/// A 168-point wide playlist tile for the horizontally scrolling "Made for you"
/// strip.
final class PlaylistCardView: UIView {
    private let artworkContainer = UIView()
    private let artworkGradientLayer = CAGradientLayer()
    private let symbolImageView = UIImageView()
    private let subtitleLabel = UILabel()
    private let nameLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.primaryLabel, numberOfLines: 2)
    private let detailLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption2), color: DemoPalette.secondaryLabel)

    init(playlist: Playlist) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        artworkContainer.translatesAutoresizingMaskIntoConstraints = false
        artworkContainer.layer.cornerRadius = 18
        artworkContainer.layer.cornerCurve = .continuous
        artworkContainer.layer.masksToBounds = true
        artworkGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        artworkGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        artworkContainer.layer.addSublayer(artworkGradientLayer)

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.tintColor = UIColor.white.withAlphaComponent(0.9)
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title3)
        symbolImageView.contentMode = .left

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let overlayStackView = UIStackView(
            axis: .vertical,
            spacing: 4,
            alignment: .leading,
            arrangedSubviews: [symbolImageView, subtitleLabel]
        )
        artworkContainer.addSubview(overlayStackView)

        nameLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)

        let cardStackView = UIStackView(
            axis: .vertical,
            spacing: 10,
            alignment: .leading,
            arrangedSubviews: [artworkContainer, nameLabel, detailLabel]
        )
        cardStackView.setCustomSpacing(2, after: nameLabel)
        addSubview(cardStackView)
        cardStackView.pinEdges(to: self)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 168),
            artworkContainer.widthAnchor.constraint(equalToConstant: 168),
            artworkContainer.heightAnchor.constraint(equalToConstant: 168),
            overlayStackView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor, constant: 14),
            overlayStackView.trailingAnchor.constraint(lessThanOrEqualTo: artworkContainer.trailingAnchor, constant: -14),
            overlayStackView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor, constant: -14),
        ])

        configure(with: playlist)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(with playlist: Playlist) {
        let baseColor = playlist.tint.color
        artworkGradientLayer.colors = [
            baseColor.withAlphaComponent(1).cgColor,
            baseColor.withAlphaComponent(0.6).cgColor,
        ]
        symbolImageView.image = UIImage(systemName: playlist.symbolName)
        subtitleLabel.attributedText = NSAttributedString(
            string: playlist.subtitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .kern: 1.4,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            ]
        )
        nameLabel.text = playlist.name
        detailLabel.text = "\(playlist.trackCount) tracks · \(playlist.durationInMinutes) min"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artworkGradientLayer.frame = artworkContainer.bounds
    }
}
