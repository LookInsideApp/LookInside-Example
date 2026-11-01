import WatchKit

/// The first screen: what the app is for, the live license state, and a row
/// per demo.
///
/// WatchKit builds every interface object here from real UIKit views
/// (SPInterfaceLabel, SPInterfaceListView, …) that the app never sees;
/// LookInside shows them.
final class MenuInterfaceController: WKInterfaceController {
    private struct Demo {
        let title: String
        let symbolName: String
        let tint: DemoTint
        let controllerIdentifier: String
    }

    private let demos = [
        Demo(title: "Now Playing", symbolName: "play.circle.fill", tint: .pink, controllerIdentifier: "NowPlaying"),
        Demo(title: "Playlists", symbolName: "music.note.list", tint: .purple, controllerIdentifier: "Playlists"),
        Demo(title: "Feed", symbolName: "text.bubble.fill", tint: .blue, controllerIdentifier: "Feed"),
        Demo(title: "Controls", symbolName: "slider.horizontal.3", tint: .orange, controllerIdentifier: "Controls"),
    ]

    @IBOutlet private var logoImage: WKInterfaceImage!
    @IBOutlet private var statusLabel: WKInterfaceLabel!
    @IBOutlet private var menuTable: WKInterfaceTable!

    private var licenseObserver: NSObjectProtocol?
    private var licenseTimer: Timer?
    private var hasOpenedLaunchDemo = false

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setTitle("LookInside")
        logoImage.setImage(UIImage(systemName: "square.3.layers.3d"))
        logoImage.setTintColor(DemoTint.blue.uiColor)

        menuTable.setNumberOfRows(demos.count, withRowType: "MenuRow")
        for (index, demo) in demos.enumerated() {
            guard let row = menuTable.rowController(at: index) as? MenuRowController else { continue }
            row.iconImage.setImage(UIImage(systemName: demo.symbolName))
            row.iconImage.setTintColor(demo.tint.uiColor)
            row.titleLabel.setText(demo.title)
        }
        refreshLicenseState()
    }

    override func willActivate() {
        super.willActivate()
        refreshLicenseState()
        // Polled as well as observed: the notification only fires on a
        // change, and the server may have verified before this screen
        // appeared.
        licenseObserver = NotificationCenter.default.addObserver(forName: .lookInsideServerLicenseStateDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.refreshLicenseState()
        }
        licenseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshLicenseState()
        }
    }

    override func didAppear() {
        super.didAppear()
        // Launched with `-demo Controls` (or NowPlaying, Playlists, Feed), the
        // app opens that demo straight away, for screenshots and checks that
        // cannot tap.
        guard !hasOpenedLaunchDemo else { return }
        hasOpenedLaunchDemo = true
        if let identifier = UserDefaults.standard.string(forKey: "demo"),
           demos.contains(where: { $0.controllerIdentifier == identifier })
        {
            pushController(withName: identifier, context: nil)
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
        licenseTimer?.invalidate()
        licenseTimer = nil
        if let licenseObserver {
            NotificationCenter.default.removeObserver(licenseObserver)
        }
        licenseObserver = nil
    }

    override func table(_: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        pushController(withName: demos[rowIndex].controllerIdentifier, context: nil)
    }

    private func refreshLicenseState() {
        let isLicensed = LookInsideServerRuntime.isLicensed
        statusLabel.setText(isLicensed ? "License verified" : "License not verified")
        statusLabel.setTextColor(isLicensed ? DemoTint.green.uiColor : .lightGray)
    }
}

final class MenuRowController: NSObject {
    @IBOutlet var iconImage: WKInterfaceImage!
    @IBOutlet var titleLabel: WKInterfaceLabel!
}
