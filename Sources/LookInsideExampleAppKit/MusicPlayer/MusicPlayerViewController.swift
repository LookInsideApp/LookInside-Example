import AppKit

/// The "Listening" screen: a vertical `NSStackView` inside an `NSScrollView`,
/// with a hand-drawn artwork view and standard AppKit controls.
final class MusicPlayerViewController: NSViewController {
    private let scrollView = NSScrollView()
    private let documentView = FlippedView()
    private let contentStackView = NSStackView(orientation: .vertical, spacing: 24, alignment: .centerX)

    private let artworkView = AlbumArtworkView()
    private let trackTitleLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .title2).withWeight(.bold),
        color: DemoPalette.primaryLabel,
        alignment: .center,
        maximumNumberOfLines: 2
    )
    private let artistLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body),
        color: DemoPalette.secondaryLabel,
        alignment: .center
    )
    private let albumLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption2),
        color: DemoPalette.tertiaryLabel,
        alignment: .center
    )

    private let progressSlider = NSSlider()
    private let elapsedTimeLabel = NSTextField.demoLabel(
        font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        color: DemoPalette.secondaryLabel
    )
    private let remainingTimeLabel = NSTextField.demoLabel(
        font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        color: DemoPalette.secondaryLabel,
        alignment: .right
    )

    private let playPauseBackgroundView = GradientView(cornerRadius: 34)
    private let playPauseButton = NSButton()
    private let shuffleButton = NSButton()
    private let repeatButton = NSButton()
    private let volumeSlider = NSSlider()

    private let upNextCardView = CardBoxView()
    private let upNextRowsStackView = NSStackView(orientation: .vertical, spacing: 0, alignment: .leading)

    private var currentTrackIndex = 0
    private var isPlaying = true
    private var isShuffling = false
    private var repeatMode: RepeatMode = .off

    private var currentTrack: MusicTrack {
        MusicTrack.queue[currentTrackIndex]
    }

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        buildScrollView(in: containerView)
        contentStackView.addArrangedSubview(makeNowPlayingSection())
        contentStackView.addArrangedSubview(makeProgressSection())
        contentStackView.addArrangedSubview(makeTransportSection())
        contentStackView.addArrangedSubview(makeSecondaryControlsSection())
        contentStackView.addArrangedSubview(makeUpNextSection())
        contentStackView.addArrangedSubview(makePlaylistSection())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyCurrentTrack()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        artworkView.setPulsing(isPlaying)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        artworkView.setPulsing(false)
    }

    // MARK: - Layout

    private func buildScrollView(in containerView: NSView) {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        containerView.addSubview(scrollView)
        scrollView.pinEdges(to: containerView)

        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView
        documentView.addSubview(contentStackView)

        let clipView = scrollView.contentView
        let preferredWidthConstraint = contentStackView.widthAnchor.constraint(
            equalTo: documentView.widthAnchor,
            constant: -48
        )
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: clipView.widthAnchor),

            contentStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 28),
            contentStackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -28),
            contentStackView.centerXAnchor.constraint(equalTo: documentView.centerXAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: documentView.leadingAnchor, constant: 24),
            contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth),
            preferredWidthConstraint,
        ])
    }

    private func makeNowPlayingSection() -> NSView {
        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 6,
            alignment: .centerX,
            views: [trackTitleLabel, artistLabel, albumLabel]
        )

        let sectionStackView = NSStackView(
            orientation: .vertical,
            spacing: 20,
            alignment: .centerX,
            views: [artworkView, textColumnStackView]
        )

        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 240),
            artworkView.heightAnchor.constraint(equalToConstant: 240),
            textColumnStackView.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor),
        ])
        return sectionStackView
    }

    private func makeProgressSection() -> NSView {
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minValue = 0
        progressSlider.maxValue = 1
        progressSlider.doubleValue = 0.32
        progressSlider.target = self
        progressSlider.action = #selector(progressSliderChanged)

        let timeRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 8,
            alignment: .firstBaseline,
            views: [elapsedTimeLabel, NSView.flexibleSpacer(), remainingTimeLabel]
        )

        let sectionStackView = NSStackView(
            orientation: .vertical,
            spacing: 8,
            alignment: .leading,
            views: [progressSlider, timeRowStackView]
        )
        NSLayoutConstraint.activate([
            progressSlider.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor),
            timeRowStackView.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor),
        ])
        return sectionStackView
    }

    private func makeTransportSection() -> NSView {
        let previousTrackButton = NSButton.demoSymbolButton(
            symbolName: "backward.fill",
            pointSize: 18,
            target: self,
            action: #selector(playPreviousTrack)
        )
        previousTrackButton.contentTintColor = DemoPalette.primaryLabel

        let nextTrackButton = NSButton.demoSymbolButton(
            symbolName: "forward.fill",
            pointSize: 18,
            target: self,
            action: #selector(playNextTrack)
        )
        nextTrackButton.contentTintColor = DemoPalette.primaryLabel

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.isBordered = false
        playPauseButton.bezelStyle = .shadowlessSquare
        playPauseButton.imagePosition = .imageOnly
        playPauseButton.contentTintColor = .white
        playPauseButton.target = self
        playPauseButton.action = #selector(togglePlayback)
        playPauseBackgroundView.addSubview(playPauseButton)

        let transportStackView = NSStackView(
            orientation: .horizontal,
            spacing: 28,
            alignment: .centerY,
            views: [previousTrackButton, playPauseBackgroundView, nextTrackButton]
        )

        NSLayoutConstraint.activate([
            playPauseBackgroundView.widthAnchor.constraint(equalToConstant: 68),
            playPauseBackgroundView.heightAnchor.constraint(equalToConstant: 68),
            playPauseButton.centerXAnchor.constraint(equalTo: playPauseBackgroundView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: playPauseBackgroundView.centerYAnchor),
        ])
        return transportStackView
    }

    private func makeSecondaryControlsSection() -> NSView {
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.image = NSImage.demoSymbol("shuffle", pointSize: 15)
        shuffleButton.imagePosition = .imageOnly
        shuffleButton.isBordered = false
        shuffleButton.bezelStyle = .shadowlessSquare
        shuffleButton.target = self
        shuffleButton.action = #selector(toggleShuffle)

        repeatButton.translatesAutoresizingMaskIntoConstraints = false
        repeatButton.imagePosition = .imageOnly
        repeatButton.isBordered = false
        repeatButton.bezelStyle = .shadowlessSquare
        repeatButton.target = self
        repeatButton.action = #selector(cycleRepeatMode)

        let quietSpeakerImageView = NSImageView()
        quietSpeakerImageView.translatesAutoresizingMaskIntoConstraints = false
        quietSpeakerImageView.image = NSImage.demoSymbol("speaker.fill", pointSize: 12)
        quietSpeakerImageView.contentTintColor = DemoPalette.secondaryLabel

        let loudSpeakerImageView = NSImageView()
        loudSpeakerImageView.translatesAutoresizingMaskIntoConstraints = false
        loudSpeakerImageView.image = NSImage.demoSymbol("speaker.wave.3.fill", pointSize: 12)
        loudSpeakerImageView.contentTintColor = DemoPalette.secondaryLabel

        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.minValue = 0
        volumeSlider.maxValue = 1
        volumeSlider.doubleValue = 0.65
        volumeSlider.widthAnchor.constraint(equalToConstant: 140).isActive = true

        let volumeStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [quietSpeakerImageView, volumeSlider, loudSpeakerImageView]
        )

        return NSStackView(
            orientation: .horizontal,
            spacing: 12,
            alignment: .centerY,
            views: [shuffleButton, NSView.flexibleSpacer(), volumeStackView, NSView.flexibleSpacer(), repeatButton]
        )
    }

    private func makeUpNextSection() -> NSView {
        let headerLabel = NSTextField.demoLabel(
            "Up Next",
            font: .preferredFont(forTextStyle: .headline),
            color: DemoPalette.primaryLabel
        )

        let seeQueueButton = NSButton(title: "See queue", target: self, action: #selector(scrollToQueue))
        seeQueueButton.translatesAutoresizingMaskIntoConstraints = false
        seeQueueButton.bezelStyle = .inline
        seeQueueButton.isBordered = false
        seeQueueButton.contentTintColor = DemoPalette.accent

        let headerRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 8,
            alignment: .firstBaseline,
            views: [headerLabel, NSView.flexibleSpacer(), seeQueueButton]
        )

        upNextCardView.contentView?.addSubview(upNextRowsStackView)
        if let cardContentView = upNextCardView.contentView {
            upNextRowsStackView.pinEdges(to: cardContentView)
        }

        let sectionStackView = NSStackView(
            orientation: .vertical,
            spacing: 12,
            alignment: .leading,
            views: [headerRowStackView, upNextCardView]
        )
        NSLayoutConstraint.activate([
            headerRowStackView.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor),
            upNextCardView.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor),
        ])
        return sectionStackView
    }

    private func makePlaylistSection() -> NSView {
        let headerLabel = NSTextField.demoLabel(
            "Made for you",
            font: .preferredFont(forTextStyle: .headline),
            color: DemoPalette.primaryLabel
        )

        let horizontalScrollView = NSScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        horizontalScrollView.hasHorizontalScroller = true
        horizontalScrollView.hasVerticalScroller = false
        horizontalScrollView.drawsBackground = false
        horizontalScrollView.horizontalScrollElasticity = .allowed

        let playlistRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 14,
            alignment: .top,
            views: Playlist.samples.map { PlaylistCardView(playlist: $0) }
        )
        let playlistDocumentView = FlippedView()
        playlistDocumentView.translatesAutoresizingMaskIntoConstraints = false
        playlistDocumentView.addSubview(playlistRowStackView)
        playlistRowStackView.pinEdges(to: playlistDocumentView)
        horizontalScrollView.documentView = playlistDocumentView

        let sectionStackView = NSStackView(
            orientation: .vertical,
            spacing: 12,
            alignment: .leading,
            views: [headerLabel, horizontalScrollView]
        )

        NSLayoutConstraint.activate([
            playlistDocumentView.heightAnchor.constraint(equalTo: horizontalScrollView.contentView.heightAnchor),
            horizontalScrollView.heightAnchor.constraint(equalToConstant: 244),
            horizontalScrollView.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor),
        ])
        return sectionStackView
    }

    // MARK: - State

    private func applyCurrentTrack() {
        let track = currentTrack
        artworkView.configure(with: track)
        artworkView.setPulsing(isPlaying)

        trackTitleLabel.stringValue = track.title
        artistLabel.stringValue = track.artist
        albumLabel.attributedStringValue = NSAttributedString(
            string: track.album.uppercased(),
            attributes: [
                .font: NSFont.preferredFont(forTextStyle: .caption2).withWeight(.semibold),
                .kern: 1.5,
                .foregroundColor: DemoPalette.tertiaryLabel,
            ]
        )

        progressSlider.trackFillColor = track.tint.color
        updateTimeLabels()
        updatePlayPauseAppearance()
        updateSecondaryControlAppearance()
        rebuildUpNextRows()
    }

    private func updateTimeLabels() {
        let elapsed = currentTrack.duration * progressSlider.doubleValue
        elapsedTimeLabel.stringValue = DemoDurationFormatter.minuteSecond(elapsed)
        remainingTimeLabel.stringValue = "-" + DemoDurationFormatter.minuteSecond(currentTrack.duration - elapsed)
    }

    private func updatePlayPauseAppearance() {
        playPauseBackgroundView.setColors([
            currentTrack.tint.color,
            currentTrack.tint.color.withAlphaComponent(0.7),
        ])
        playPauseButton.image = NSImage.demoSymbol(isPlaying ? "pause.fill" : "play.fill", pointSize: 24, weight: .bold)
    }

    private func updateSecondaryControlAppearance() {
        shuffleButton.contentTintColor = isShuffling ? currentTrack.tint.color : DemoPalette.secondaryLabel
        repeatButton.image = NSImage.demoSymbol(repeatMode.symbolName, pointSize: 15)
        repeatButton.contentTintColor = repeatMode == .off ? DemoPalette.secondaryLabel : currentTrack.tint.color
    }

    private func rebuildUpNextRows() {
        for existingRow in upNextRowsStackView.arrangedSubviews {
            upNextRowsStackView.removeArrangedSubview(existingRow)
            existingRow.removeFromSuperview()
        }

        let upcoming = Array(MusicTrack.queue.enumerated().dropFirst(currentTrackIndex + 1).prefix(3))
        for (offset, element) in upcoming.enumerated() {
            let rowView = QueueRowView(track: element.element, isCurrent: false) { [weak self] in
                self?.selectTrack(at: element.offset)
            }
            upNextRowsStackView.addArrangedSubview(rowView)
            rowView.widthAnchor.constraint(equalTo: upNextRowsStackView.widthAnchor).isActive = true

            if offset < upcoming.count - 1 {
                let hairlineView = HairlineView()
                upNextRowsStackView.addArrangedSubview(hairlineView)
                hairlineView.widthAnchor.constraint(equalTo: upNextRowsStackView.widthAnchor).isActive = true
            }
        }
        upNextCardView.isHidden = upcoming.isEmpty
    }

    private func selectTrack(at index: Int) {
        currentTrackIndex = max(0, min(MusicTrack.queue.count - 1, index))
        progressSlider.doubleValue = 0
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

    /// The Mac layout has no modal sheet for the queue — the "Up Next" card is
    /// already on screen, so the button just scrolls it into view.
    @objc
    private func scrollToQueue() {
        upNextCardView.scrollToVisible(upNextCardView.bounds)
    }
}
