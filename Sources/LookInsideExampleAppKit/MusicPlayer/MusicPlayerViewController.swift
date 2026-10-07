import AppKit

/// The Music screen: a now-playing panel — artwork beside the transport
/// controls, the way a Mac player lays it out — above the queue and a
/// horizontally scrolling playlist strip, all in one vertical `NSStackView`
/// inside an `NSScrollView`.
final class MusicPlayerViewController: NSViewController {
    private let contentStackView = NSStackView(orientation: .vertical, spacing: 32, alignment: .leading)

    private let artworkView = AlbumArtworkView()
    private let trackTitleLabel = NSTextField.demoLabel(
        font: .systemFont(ofSize: 24, weight: .bold),
        color: DemoPalette.primaryLabel,
        maximumNumberOfLines: 2
    )
    private let artistLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .title3),
        color: DemoPalette.secondaryLabel
    )
    private let albumLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .caption2),
        color: DemoPalette.tertiaryLabel
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

    private let playPauseBackgroundView = GradientView(cornerRadius: 26)
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
    private var showsFullQueue = false
    private let seeQueueButton = NSButton()

    private var currentTrack: MusicTrack {
        MusicTrack.queue[currentTrackIndex]
    }

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        contentStackView.addArrangedSubview(makeNowPlayingPanel())
        contentStackView.addArrangedSubview(makeUpNextSection())
        contentStackView.addArrangedSubview(makePlaylistSection())
        for sectionView in contentStackView.arrangedSubviews {
            sectionView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor).isActive = true
        }
        NSScrollView.installCenteredColumn(contentStackView, in: containerView, maximumWidth: 760, verticalInset: 28)
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

    private func makeNowPlayingPanel() -> NSView {
        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 4,
            alignment: .leading,
            views: [trackTitleLabel, artistLabel, albumLabel]
        )
        textColumnStackView.setCustomSpacing(8, after: artistLabel)

        let controlsColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 18,
            alignment: .leading,
            views: [
                textColumnStackView,
                makeProgressSection(),
                makeTransportSection(),
                makeVolumeSection(),
            ]
        )
        for columnView in controlsColumnStackView.arrangedSubviews {
            columnView.widthAnchor.constraint(equalTo: controlsColumnStackView.widthAnchor).isActive = true
        }
        controlsColumnStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 220),
            artworkView.heightAnchor.constraint(equalToConstant: 220),
        ])

        return NSStackView(
            orientation: .horizontal,
            spacing: 32,
            alignment: .centerY,
            views: [artworkView, controlsColumnStackView]
        )
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
            pointSize: 20,
            target: self,
            action: #selector(playPreviousTrack)
        )
        previousTrackButton.contentTintColor = DemoPalette.primaryLabel
        previousTrackButton.setAccessibilityLabel("Previous track")

        let nextTrackButton = NSButton.demoSymbolButton(
            symbolName: "forward.fill",
            pointSize: 20,
            target: self,
            action: #selector(playNextTrack)
        )
        nextTrackButton.contentTintColor = DemoPalette.primaryLabel
        nextTrackButton.setAccessibilityLabel("Next track")

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.isBordered = false
        playPauseButton.bezelStyle = .shadowlessSquare
        playPauseButton.imagePosition = .imageOnly
        playPauseButton.contentTintColor = .white
        playPauseButton.target = self
        playPauseButton.action = #selector(togglePlayback)
        playPauseBackgroundView.addSubview(playPauseButton)

        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.image = NSImage.demoSymbol("shuffle", pointSize: 15)
        shuffleButton.imagePosition = .imageOnly
        shuffleButton.isBordered = false
        shuffleButton.bezelStyle = .shadowlessSquare
        shuffleButton.target = self
        shuffleButton.action = #selector(toggleShuffle)
        shuffleButton.setAccessibilityLabel("Shuffle")

        repeatButton.translatesAutoresizingMaskIntoConstraints = false
        repeatButton.imagePosition = .imageOnly
        repeatButton.isBordered = false
        repeatButton.bezelStyle = .shadowlessSquare
        repeatButton.target = self
        repeatButton.action = #selector(cycleRepeatMode)
        repeatButton.setAccessibilityLabel("Repeat")

        let transportStackView = NSStackView(
            orientation: .horizontal,
            spacing: 24,
            alignment: .centerY,
            views: [
                shuffleButton,
                NSView.flexibleSpacer(),
                previousTrackButton,
                playPauseBackgroundView,
                nextTrackButton,
                NSView.flexibleSpacer(),
                repeatButton,
            ]
        )

        NSLayoutConstraint.activate([
            playPauseBackgroundView.widthAnchor.constraint(equalToConstant: 52),
            playPauseBackgroundView.heightAnchor.constraint(equalToConstant: 52),
            playPauseButton.centerXAnchor.constraint(equalTo: playPauseBackgroundView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: playPauseBackgroundView.centerYAnchor),
        ])
        return transportStackView
    }

    private func makeVolumeSection() -> NSView {
        let quietSpeakerImageView = NSImageView()
        quietSpeakerImageView.translatesAutoresizingMaskIntoConstraints = false
        quietSpeakerImageView.image = NSImage.demoSymbol("speaker.fill", pointSize: 11)
        quietSpeakerImageView.contentTintColor = DemoPalette.secondaryLabel

        let loudSpeakerImageView = NSImageView()
        loudSpeakerImageView.translatesAutoresizingMaskIntoConstraints = false
        loudSpeakerImageView.image = NSImage.demoSymbol("speaker.wave.3.fill", pointSize: 11)
        loudSpeakerImageView.contentTintColor = DemoPalette.secondaryLabel

        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.minValue = 0
        volumeSlider.maxValue = 1
        volumeSlider.doubleValue = 0.65
        volumeSlider.controlSize = .small
        volumeSlider.setAccessibilityLabel("Volume")

        return NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [quietSpeakerImageView, volumeSlider, loudSpeakerImageView]
        )
    }

    private func makeUpNextSection() -> NSView {
        let headerLabel = NSTextField.demoLabel(
            "Up Next",
            font: .preferredFont(forTextStyle: .headline),
            color: DemoPalette.primaryLabel
        )

        seeQueueButton.title = "Show All"
        seeQueueButton.target = self
        seeQueueButton.action = #selector(toggleFullQueue)
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
            "Made for You",
            font: .preferredFont(forTextStyle: .headline),
            color: DemoPalette.primaryLabel
        )

        let horizontalScrollView = NSScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        horizontalScrollView.hasHorizontalScroller = true
        horizontalScrollView.hasVerticalScroller = false
        horizontalScrollView.drawsBackground = false
        horizontalScrollView.applyDemoScrollerStyle()
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
        playPauseButton.image = NSImage.demoSymbol(isPlaying ? "pause.fill" : "play.fill", pointSize: 20, weight: .bold)
        playPauseButton.setAccessibilityLabel(isPlaying ? "Pause" : "Play")
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

        let upcoming = Array(
            MusicTrack.queue.enumerated()
                .dropFirst(currentTrackIndex + 1)
                .prefix(showsFullQueue ? MusicTrack.queue.count : 3)
        )
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

    /// The Mac layout has no modal sheet for the queue: the button expands
    /// the "Up Next" card in place instead.
    @objc
    private func toggleFullQueue() {
        showsFullQueue.toggle()
        seeQueueButton.title = showsFullQueue ? "Show Less" : "Show All"
        rebuildUpNextRows()
    }
}
