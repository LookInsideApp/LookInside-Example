import WatchKit

/// The WatchKit controls in one screen: switches, a slider and a button.
final class ControlsInterfaceController: WKInterfaceController {
    @IBOutlet private var volumeLabel: WKInterfaceLabel!
    @IBOutlet private var sendButton: WKInterfaceButton!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setTitle("Controls")
        updateVolume(6)
        sendButton.setBackgroundColor(DemoTint.blue.uiColor)
    }

    @IBAction private func shuffleChanged(_: Bool) {}

    @IBAction private func repeatChanged(_: Bool) {}

    @IBAction private func volumeChanged(_ value: Float) {
        updateVolume(value)
    }

    @IBAction private func sendTapped() {}

    private func updateVolume(_ value: Float) {
        volumeLabel.setText("Volume \(Int(value))")
    }
}
