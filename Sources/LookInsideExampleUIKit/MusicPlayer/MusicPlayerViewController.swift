import UIKit

/// The "Listening" screen: a scrolling column of hand-laid-out controls.
///
/// Deliberately built from `UIScrollView` + `UIStackView` + Auto Layout rather
/// than a table or collection view, so the hierarchy the LookInside host walks
/// is deep and irregular — the shape a real hand-written screen has.
final class MusicPlayerViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView(axis: .vertical, spacing: 24)

    private let artworkView = AlbumArtworkView()
    private let trackTitleLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .title2), color: DemoPalette.primaryLabel, alignment: .center, numberOfLines: 2)
    private let artistLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.secondaryLabel, alignment: .center)
    private let albumLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption2), color: DemoPalette.tertiaryLabel, alignment: .center)

    private let progressSlider = UISlider()
    private let elapsedTimeLabel = UILabel(text: nil, font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular), color: DemoPalette.secondaryLabel)
    private let remainingTimeLabel = UILabel(text: nil, font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular), color: DemoPalette.secondaryLabel, alignment: .right)

    private let previousTrackButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .custom)
    private let playPauseGradientLayer = CAGradientLayer()
    private let playPauseSymbolImageView = UIImageView()
    private let nextTrackButton = UIButton(type: .system)

    private let shuffleButton = UIButton(type: .system)
    private let repeatButton = UIButton(type: .system)
    private let volumeSlider = UISlider()

    private let upNextCardView = CardView()
    private let upNextRowsStackView = UIStackView(axis: .vertical, spacing: 0)
    private let playlistRowStackView = UIStackView(axis: .horizontal, spacing: 14, alignment: .top)

    private var currentTrackIndex = 0
    private var isPlaying = true
    private var isShuffling = false
    private var repeatMode: RepeatMode = .off

    private var currentTrack: MusicTrack {
        MusicTrack.queue[currentTrackIndex]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Listening"
        view.backgroundColor = DemoPalette.groupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: #selector(presentQueue)
        )

        buildScrollView()
        contentStackView.addArrangedSubview(makeNowPlayingSection())
        contentStackView.addArrangedSubview(makeProgressSection())
        contentStackView.addArrangedSubview(makeTransportSection())
        contentStackView.addArrangedSubview(makeSecondaryControlsSection())
        contentStackView.addArrangedSubview(makeUpNextSection())
        contentStackView.addArrangedSubview(makePlaylistSection())

        applyCurrentTrack()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        artworkView.setPulsing(isPlaying)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        artworkView.setPulsing(false)
    }

    // MARK: - Layout

    private func buildScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        scrollView.addSubview(contentStackView)

        // The content is centred and capped at `contentMaximumWidth`, so on iPad
        // it stops stretching edge to edge. The preferred width is only
        // `defaultHigh`, letting the required cap win once the screen is wide.
        let preferredWidthConstraint = contentStackView.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor,
            constant: -48
        )
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 28),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStackView.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth),
            preferredWidthConstraint,
        ])
    }

    private func makeNowPlayingSection() -> UIView {
        let textStackView = UIStackView(
            axis: .vertical,
            spacing: 6,
            alignment: .center,
            arrangedSubviews: [trackTitleLabel, artistLabel, albumLabel]
        )
        trackTitleLabel.font = .preferredFont(forTextStyle: .title2).withWeight(.bold)

        let artworkRow = UIStackView(axis: .horizontal, alignment: .center, arrangedSubviews: [artworkView])
        artworkRow.distribution = .equalCentering
        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 240),
            artworkView.heightAnchor.constraint(equalToConstant: 240),
            artworkView.centerXAnchor.constraint(equalTo: artworkRow.centerXAnchor),
        ])

        return UIStackView(
            axis: .vertical,
            spacing: 20,
            arrangedSubviews: [artworkRow, textStackView]
        )
    }

    private func makeProgressSection() -> UIView {
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0.32
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)

        let timeRow = UIStackView(
            axis: .horizontal,
            alignment: .firstBaseline,
            arrangedSubviews: [elapsedTimeLabel, UIView.flexibleSpacer(), remainingTimeLabel]
        )

        return UIStackView(axis: .vertical, spacing: 8, arrangedSubviews: [progressSlider, timeRow])
    }

    private func makeTransportSection() -> UIView {
        previousTrackButton.setImage(UIImage(systemName: "backward.fill", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)), for: .normal)
        previousTrackButton.addTarget(self, action: #selector(playPreviousTrack), for: .touchUpInside)

        nextTrackButton.setImage(UIImage(systemName: "forward.fill", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)), for: .normal)
        nextTrackButton.addTarget(self, action: #selector(playNextTrack), for: .touchUpInside)

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.layer.cornerRadius = 36
        playPauseButton.layer.addSublayer(playPauseGradientLayer)
        playPauseGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        playPauseGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        playPauseGradientLayer.cornerRadius = 36
        playPauseButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)

        playPauseSymbolImageView.translatesAutoresizingMaskIntoConstraints = false
        playPauseSymbolImageView.tintColor = .white
        playPauseSymbolImageView.contentMode = .center
        playPauseSymbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
        playPauseButton.addSubview(playPauseSymbolImageView)

        NSLayoutConstraint.activate([
            playPauseButton.widthAnchor.constraint(equalToConstant: 72),
            playPauseButton.heightAnchor.constraint(equalToConstant: 72),
            playPauseSymbolImageView.centerXAnchor.constraint(equalTo: playPauseButton.centerXAnchor),
            playPauseSymbolImageView.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
        ])

        let transportStackView = UIStackView(
            axis: .horizontal,
            spacing: 28,
            alignment: .center,
            arrangedSubviews: [previousTrackButton, playPauseButton, nextTrackButton]
        )

        let centeringContainer = UIView()
        centeringContainer.translatesAutoresizingMaskIntoConstraints = false
        centeringContainer.addSubview(transportStackView)
        NSLayoutConstraint.activate([
            transportStackView.topAnchor.constraint(equalTo: centeringContainer.topAnchor),
            transportStackView.bottomAnchor.constraint(equalTo: centeringContainer.bottomAnchor),
            transportStackView.centerXAnchor.constraint(equalTo: centeringContainer.centerXAnchor),
        ])
        return centeringContainer
    }

    private func makeSecondaryControlsSection() -> UIView {
        shuffleButton.setImage(UIImage(systemName: "shuffle", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title3)), for: .normal)
        shuffleButton.addTarget(self, action: #selector(toggleShuffle), for: .touchUpInside)

        repeatButton.addTarget(self, action: #selector(cycleRepeatMode), for: .touchUpInside)

        let quietSpeakerImageView = UIImageView(image: UIImage(systemName: "speaker.fill"))
        quietSpeakerImageView.tintColor = DemoPalette.secondaryLabel
        let loudSpeakerImageView = UIImageView(image: UIImage(systemName: "speaker.wave.3.fill"))
        loudSpeakerImageView.tintColor = DemoPalette.secondaryLabel

        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.value = 0.65
        volumeSlider.minimumTrackTintColor = DemoPalette.secondaryLabel
        volumeSlider.widthAnchor.constraint(equalToConstant: 140).isActive = true

        let volumeStackView = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .center,
            arrangedSubviews: [quietSpeakerImageView, volumeSlider, loudSpeakerImageView]
        )

        return UIStackView(
            axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [
                shuffleButton,
                UIView.flexibleSpacer(),
                volumeStackView,
                UIView.flexibleSpacer(),
                repeatButton,
            ]
        )
    }

    private func makeUpNextSection() -> UIView {
        let headerLabel = UILabel(text: "Up Next", font: .preferredFont(forTextStyle: .headline), color: DemoPalette.primaryLabel)
        let seeQueueButton = UIButton(type: .system)
        seeQueueButton.setTitle("See queue", for: .normal)
        seeQueueButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        seeQueueButton.addTarget(self, action: #selector(presentQueue), for: .touchUpInside)

        let headerRow = UIStackView(
            axis: .horizontal,
            alignment: .firstBaseline,
            arrangedSubviews: [headerLabel, UIView.flexibleSpacer(), seeQueueButton]
        )

        upNextCardView.addSubview(upNextRowsStackView)
        upNextRowsStackView.pinEdges(to: upNextCardView)

        return UIStackView(axis: .vertical, spacing: 12, arrangedSubviews: [headerRow, upNextCardView])
    }

    private func makePlaylistSection() -> UIView {
        let headerLabel = UILabel(text: "Made for you", font: .preferredFont(forTextStyle: .headline), color: DemoPalette.primaryLabel)

        let horizontalScrollView = UIScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.clipsToBounds = false

        for playlist in Playlist.samples {
            playlistRowStackView.addArrangedSubview(PlaylistCardView(playlist: playlist))
        }
        horizontalScrollView.addSubview(playlistRowStackView)
        playlistRowStackView.pinEdges(to: horizontalScrollView)
        playlistRowStackView.heightAnchor.constraint(equalTo: horizontalScrollView.heightAnchor).isActive = true
        horizontalScrollView.heightAnchor.constraint(equalToConstant: 232).isActive = true

        return UIStackView(axis: .vertical, spacing: 12, arrangedSubviews: [headerLabel, horizontalScrollView])
    }

    // MARK: - State

    private func applyCurrentTrack() {
        let track = currentTrack
        artworkView.configure(with: track)
        artworkView.setPulsing(isPlaying)

        trackTitleLabel.text = track.title
        artistLabel.text = track.artist
        albumLabel.attributedText = NSAttributedString(
            string: track.album.uppercased(),
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption2).withWeight(.semibold),
                .kern: 1.5,
                .foregroundColor: DemoPalette.tertiaryLabel,
            ]
        )

        progressSlider.minimumTrackTintColor = track.tint.color
        updateTimeLabels()
        updatePlayPauseAppearance()
        updateSecondaryControlAppearance()
        rebuildUpNextRows()
    }

    private func updateTimeLabels() {
        let elapsed = currentTrack.duration * Double(progressSlider.value)
        elapsedTimeLabel.text = DemoDurationFormatter.minuteSecond(elapsed)
        remainingTimeLabel.text = "-" + DemoDurationFormatter.minuteSecond(currentTrack.duration - elapsed)
    }

    private func updatePlayPauseAppearance() {
        let baseColor = currentTrack.tint.color
        playPauseGradientLayer.colors = [
            baseColor.withAlphaComponent(1).cgColor,
            baseColor.withAlphaComponent(0.7).cgColor,
        ]
        playPauseButton.layer.shadowColor = baseColor.cgColor
        playPauseButton.layer.shadowOpacity = 0.45
        playPauseButton.layer.shadowRadius = 18
        playPauseButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        playPauseSymbolImageView.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
        playPauseSymbolImageView.transform = isPlaying ? .identity : CGAffineTransform(translationX: 2, y: 0)
    }

    private func updateSecondaryControlAppearance() {
        shuffleButton.tintColor = isShuffling ? currentTrack.tint.color : DemoPalette.secondaryLabel
        repeatButton.setImage(
            UIImage(systemName: repeatMode.symbolName, withConfiguration: UIImage.SymbolConfiguration(textStyle: .title3)),
            for: .normal
        )
        repeatButton.tintColor = repeatMode == .off ? DemoPalette.secondaryLabel : currentTrack.tint.color
    }

    private func rebuildUpNextRows() {
        for existingRow in upNextRowsStackView.arrangedSubviews {
            upNextRowsStackView.removeArrangedSubview(existingRow)
            existingRow.removeFromSuperview()
        }

        let upcoming = Array(MusicTrack.queue.enumerated().dropFirst(currentTrackIndex + 1).prefix(3))
        for (offset, element) in upcoming.enumerated() {
            let row = QueueRowView(track: element.element, isCurrent: false) { [weak self] in
                self?.selectTrack(at: element.offset)
            }
            upNextRowsStackView.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: upNextRowsStackView.widthAnchor).isActive = true

            if offset < upcoming.count - 1 {
                let hairlineContainer = UIView()
                hairlineContainer.translatesAutoresizingMaskIntoConstraints = false
                let hairline = HairlineView()
                hairlineContainer.addSubview(hairline)
                NSLayoutConstraint.activate([
                    hairline.leadingAnchor.constraint(equalTo: hairlineContainer.leadingAnchor, constant: 64),
                    hairline.trailingAnchor.constraint(equalTo: hairlineContainer.trailingAnchor),
                    hairline.topAnchor.constraint(equalTo: hairlineContainer.topAnchor),
                    hairline.bottomAnchor.constraint(equalTo: hairlineContainer.bottomAnchor),
                ])
                upNextRowsStackView.addArrangedSubview(hairlineContainer)
                hairlineContainer.widthAnchor.constraint(equalTo: upNextRowsStackView.widthAnchor).isActive = true
            }
        }

        upNextCardView.isHidden = upcoming.isEmpty
    }

    private func selectTrack(at index: Int) {
        currentTrackIndex = max(0, min(MusicTrack.queue.count - 1, index))
        progressSlider.value = 0
        applyCurrentTrack()
    }

    // MARK: - Actions

    @objc
    private func progressSliderChanged() {
        updateTimeLabels()
    }

    @objc
    private func togglePlayback() {
        isPlaying.toggle()
        updatePlayPauseAppearance()
        artworkView.setPulsing(isPlaying)
    }

    @objc
    private func playPreviousTrack() {
        selectTrack(at: currentTrackIndex - 1)
    }

    @objc
    private func playNextTrack() {
        selectTrack(at: currentTrackIndex + 1)
    }

    @objc
    private func toggleShuffle() {
        isShuffling.toggle()
        updateSecondaryControlAppearance()
    }

    @objc
    private func cycleRepeatMode() {
        repeatMode = repeatMode.next
        updateSecondaryControlAppearance()
    }

    @objc
    private func presentQueue() {
        let queueViewController = QueueViewController(currentIndex: currentTrackIndex) { [weak self] selectedIndex in
            self?.selectTrack(at: selectedIndex)
        }
        let navigationController = UINavigationController(rootViewController: queueViewController)
        if let sheetPresentationController = navigationController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = true
        }
        present(navigationController, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playPauseGradientLayer.frame = playPauseButton.bounds
    }
}
