import UIKit

/// One row of the "Up Next" card. A `UIControl` subclass rather than a
/// `UIButton`, so the whole row is one tap target with a hand-built subview
/// stack inside it.
final class QueueRowView: UIControl {
    private let artworkContainer = UIView()
    private let artworkGradientLayer = CAGradientLayer()
    private let artworkSymbolImageView = UIImageView()
    private let titleLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.primaryLabel)
    private let artistLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1), color: DemoPalette.secondaryLabel)
    private let trailingLabel = UILabel(text: nil, font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular), color: DemoPalette.tertiaryLabel)
    private let nowPlayingImageView = UIImageView()

    private let onSelect: () -> Void

    init(track: MusicTrack, isCurrent: Bool, onSelect: @escaping () -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        artworkContainer.translatesAutoresizingMaskIntoConstraints = false
        artworkContainer.layer.cornerRadius = 10
        artworkContainer.layer.cornerCurve = .continuous
        artworkContainer.layer.masksToBounds = true
        artworkGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        artworkGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        artworkContainer.layer.addSublayer(artworkGradientLayer)

        artworkSymbolImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkSymbolImageView.tintColor = .white
        artworkSymbolImageView.contentMode = .scaleAspectFit
        artworkContainer.addSubview(artworkSymbolImageView)

        titleLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)

        nowPlayingImageView.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingImageView.image = UIImage(systemName: "waveform")
        nowPlayingImageView.contentMode = .scaleAspectFit

        let textStackView = UIStackView(
            axis: .vertical,
            spacing: 2,
            alignment: .leading,
            arrangedSubviews: [titleLabel, artistLabel]
        )

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [artworkContainer, textStackView, UIView.flexibleSpacer(), trailingLabel, nowPlayingImageView]
        )
        rowStackView.isUserInteractionEnabled = false
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self, insets: UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))

        NSLayoutConstraint.activate([
            artworkContainer.widthAnchor.constraint(equalToConstant: 44),
            artworkContainer.heightAnchor.constraint(equalToConstant: 44),
            artworkSymbolImageView.centerXAnchor.constraint(equalTo: artworkContainer.centerXAnchor),
            artworkSymbolImageView.centerYAnchor.constraint(equalTo: artworkContainer.centerYAnchor),
        ])

        configure(track: track, isCurrent: isCurrent)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(track: MusicTrack, isCurrent: Bool) {
        let baseColor = track.tint.color
        artworkGradientLayer.colors = [
            baseColor.withAlphaComponent(1).cgColor,
            baseColor.withAlphaComponent(0.6).cgColor,
        ]
        artworkSymbolImageView.image = UIImage(systemName: track.symbolName)
        titleLabel.text = track.title
        artistLabel.text = track.artist
        trailingLabel.text = DemoDurationFormatter.minuteSecond(track.duration)
        trailingLabel.isHidden = isCurrent
        nowPlayingImageView.isHidden = !isCurrent
        nowPlayingImageView.tintColor = baseColor
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? DemoPalette.separator.withAlphaComponent(0.25) : .clear
        }
    }

    @objc
    private func handleTap() {
        onSelect()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artworkGradientLayer.frame = artworkContainer.bounds
    }
}

extension UIView {
    static func flexibleSpacer() -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return spacer
    }
}

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight],
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
