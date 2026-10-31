import UIKit

/// The first item of the Music screen: the artwork beside the track details,
/// a progress bar and the transport buttons.
///
/// The cell itself never takes focus (see
/// `MusicViewController.collectionView(_:canFocusItemAt:)`), so focus moves
/// between its buttons instead.
final class NowPlayingCell: UICollectionViewCell {
    enum TransportAction {
        case toggleShuffle
        case previous
        case togglePlayback
        case next
        case cycleRepeatMode
    }

    /// Called with the button the user pressed.
    var transportActionHandler: ((TransportAction) -> Void)?

    private let artworkView = AlbumArtworkView()
    private let albumLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1), color: DemoPalette.secondaryLabel)
    private let titleLabel = UILabel(
        text: nil,
        font: .preferredFont(forTextStyle: .title2).withWeight(.bold),
        color: DemoPalette.primaryLabel
    )
    private let artistLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .title3), color: DemoPalette.secondaryLabel)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let elapsedLabel = UILabel(
        text: nil,
        font: .monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .regular),
        color: DemoPalette.secondaryLabel
    )
    private let remainingLabel = UILabel(
        text: nil,
        font: .monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .regular),
        color: DemoPalette.secondaryLabel,
        alignment: .right
    )
    private lazy var shuffleButton = makeTransportButton(symbolName: "shuffle", action: .toggleShuffle)
    private lazy var previousButton = makeTransportButton(symbolName: "backward.fill", action: .previous)
    private lazy var playbackButton = makeTransportButton(symbolName: "pause.fill", action: .togglePlayback)
    private lazy var nextButton = makeTransportButton(symbolName: "forward.fill", action: .next)
    private lazy var repeatButton = makeTransportButton(symbolName: "repeat", action: .cycleRepeatMode)

    override init(frame: CGRect) {
        super.init(frame: frame)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        let timesStackView = UIStackView(axis: .horizontal, arrangedSubviews: [elapsedLabel, remainingLabel])
        let progressStackView = UIStackView(axis: .vertical, spacing: 12, arrangedSubviews: [progressView, timesStackView])

        let transportStackView = UIStackView(
            axis: .horizontal,
            spacing: 28,
            alignment: .center,
            arrangedSubviews: [shuffleButton, previousButton, playbackButton, nextButton, repeatButton]
        )

        let detailsStackView = UIStackView(
            axis: .vertical,
            spacing: 16,
            alignment: .leading,
            arrangedSubviews: [albumLabel, titleLabel, artistLabel, progressStackView, transportStackView]
        )
        detailsStackView.setCustomSpacing(32, after: artistLabel)
        detailsStackView.setCustomSpacing(32, after: progressStackView)

        contentView.addSubview(artworkView)
        contentView.addSubview(detailsStackView)
        NSLayoutConstraint.activate([
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 400),
            artworkView.heightAnchor.constraint(equalToConstant: 400),

            detailsStackView.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 72),
            detailsStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            detailsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            progressStackView.widthAnchor.constraint(equalToConstant: 760),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        track: MusicTrack,
        isPlaying: Bool,
        isShuffled: Bool,
        repeatMode: RepeatMode,
        playbackFraction: Float
    ) {
        let tint = track.tint.color
        artworkView.configure(with: track)
        artworkView.setPulsing(isPlaying)

        albumLabel.attributedText = NSAttributedString(string: track.album.uppercased(), attributes: [
            .font: UIFont.preferredFont(forTextStyle: .caption1).withWeight(.semibold),
            .kern: 3,
            .foregroundColor: DemoPalette.secondaryLabel,
        ])
        titleLabel.text = track.title
        artistLabel.text = track.artist

        progressView.progressTintColor = tint
        progressView.progress = playbackFraction
        let elapsedSeconds = track.duration * TimeInterval(playbackFraction)
        elapsedLabel.text = DemoDurationFormatter.minuteSecond(elapsedSeconds)
        remainingLabel.text = "-" + DemoDurationFormatter.minuteSecond(track.duration - elapsedSeconds)

        playbackButton.configuration?.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
        shuffleButton.configuration?.baseForegroundColor = isShuffled ? tint : nil
        repeatButton.configuration?.image = UIImage(systemName: repeatMode.symbolName)
        repeatButton.configuration?.baseForegroundColor = repeatMode == .off ? nil : tint
    }

    private func makeTransportButton(symbolName: String, action: TransportAction) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.image = UIImage(systemName: symbolName)
        configuration.cornerStyle = .capsule
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.transportActionHandler?(action)
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
