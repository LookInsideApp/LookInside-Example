import WatchKit

/// A now-playing screen: artwork, the track, the time left and the
/// transport buttons.
final class NowPlayingInterfaceController: WKInterfaceController {
    private let track = MusicTrack.queue[0]
    private var elapsed: TimeInterval = 74
    private var isPlaying = true

    @IBOutlet private var artworkImage: WKInterfaceImage!
    @IBOutlet private var titleLabel: WKInterfaceLabel!
    @IBOutlet private var artistLabel: WKInterfaceLabel!
    @IBOutlet private var timeLabel: WKInterfaceLabel!
    @IBOutlet private var playButton: WKInterfaceButton!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setTitle("Now Playing")
        artworkImage.setImage(UIImage(systemName: track.symbolName))
        artworkImage.setTintColor(track.tint.uiColor)
        titleLabel.setText(track.title)
        artistLabel.setText(track.artist)
        update()
    }

    @IBAction private func restartTrack() {
        elapsed = 0
        update()
    }

    @IBAction private func togglePlayback() {
        isPlaying.toggle()
        update()
    }

    @IBAction private func skipForward() {
        elapsed = min(track.duration, elapsed + 30)
        update()
    }

    private func update() {
        timeLabel.setText("\(DemoDurationFormatter.minuteSecond(elapsed)) / \(DemoDurationFormatter.minuteSecond(track.duration))")
        playButton.setTitle(isPlaying ? "Pause" : "Play")
        playButton.setBackgroundColor(track.tint.uiColor)
    }
}
