import UIKit

/// The first tab: what this app is for, how to connect LookInside, the live
/// license state, and a shortcut to every demo.
///
/// Two columns of stack views that fit on one screen. Only the demo buttons
/// take focus, and a screen that scrolls by moving focus would never reveal
/// rows that cannot be focused.
final class WelcomeViewController: UIViewController {
    /// The tabs the demo buttons switch to, in tab bar order.
    enum DemoTab: Int {
        case music = 1
        case feed
        case controls
    }

    private let licenseIndicatorView = UIView()
    private let licenseValueLabel = UILabel(
        text: nil,
        font: .preferredFont(forTextStyle: .body),
        color: DemoPalette.secondaryLabel
    )
    private var licensePollingTask: Task<Void, Never>?
    private var licenseNotificationTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let introductionColumnStackView = UIStackView(
            axis: .vertical,
            spacing: 40,
            arrangedSubviews: [makeHeaderView(), makeStatusPanel()]
        )
        let actionColumnStackView = UIStackView(
            axis: .vertical,
            spacing: 40,
            arrangedSubviews: [makeStepsPanel(), makeDemosView()]
        )
        let columnsStackView = UIStackView(
            axis: .horizontal,
            spacing: 80,
            alignment: .top,
            arrangedSubviews: [introductionColumnStackView, actionColumnStackView]
        )
        view.addSubview(columnsStackView)

        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            columnsStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            columnsStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            columnsStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            columnsStackView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor),
            introductionColumnStackView.widthAnchor.constraint(equalToConstant: 720),
        ])

        updateLicenseState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLicenseState()
        // Polled as well as observed: the notification only fires on a
        // change, and the server may have verified before this screen
        // appeared.
        licensePollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.updateLicenseState()
            }
        }
        licenseNotificationTask = Task { [weak self] in
            let notificationName = Notification.Name("LookInsideServerLicenseStateDidChangeNotification")
            for await _ in NotificationCenter.default.notifications(named: notificationName) {
                self?.updateLicenseState()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        licensePollingTask?.cancel()
        licensePollingTask = nil
        licenseNotificationTask?.cancel()
        licenseNotificationTask = nil
    }

    private func updateLicenseState() {
        let isLicensed = LookInsideServerRuntime.isLicensed
        licenseIndicatorView.backgroundColor = isLicensed ? .systemGreen : DemoPalette.tertiaryLabel
        licenseValueLabel.text = isLicensed ? "Verified" : "Not verified"
    }

    // MARK: - Sections

    private func makeHeaderView() -> UIView {
        let iconTileView = SymbolTileView(symbolName: "square.3.layers.3d", tint: DemoPalette.accent, side: 120, pointSize: 54)
        let titleLabel = UILabel(
            text: "LookInside TV UIKit",
            font: .preferredFont(forTextStyle: .title2).withWeight(.bold),
            color: DemoPalette.primaryLabel
        )
        let subtitleLabel = UILabel(
            text: "Open LookInside on your Mac and choose this app to explore its live view hierarchy.",
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.secondaryLabel,
            numberOfLines: 0
        )
        let headerStackView = UIStackView(
            axis: .vertical,
            spacing: 16,
            alignment: .leading,
            arrangedSubviews: [iconTileView, titleLabel, subtitleLabel]
        )
        headerStackView.setCustomSpacing(24, after: iconTileView)
        return headerStackView
    }

    private func makeStatusPanel() -> UIView {
        licenseIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        licenseIndicatorView.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            licenseIndicatorView.widthAnchor.constraint(equalToConstant: 16),
            licenseIndicatorView.heightAnchor.constraint(equalToConstant: 16),
        ])
        let licenseValueStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [licenseIndicatorView, licenseValueLabel]
        )

        let simulatorValueLabel = UILabel(
            text: "TCP loopback · 47164–47169",
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.secondaryLabel
        )

        return PanelView(
            title: "Status",
            footer: "LookInside verifies its license each time it connects to this app.",
            rows: [
                PanelRowView(title: "License", accessory: licenseValueStackView),
                PanelRowView(title: "Simulator", accessory: simulatorValueLabel),
            ]
        )
    }

    private func makeStepsPanel() -> UIView {
        PanelView(title: "Get Started", rows: [
            PanelRowView(
                title: "Install LookInside",
                subtitle: "Download it on your Mac from lookinside-app.com.",
                symbolName: "arrow.down",
                symbolTint: .systemBlue
            ),
            PanelRowView(
                title: "Run this app",
                subtitle: "In the Apple TV simulator on the same Mac.",
                symbolName: "play.fill",
                symbolTint: .systemGreen
            ),
            PanelRowView(
                title: "Choose it in LookInside",
                subtitle: "Select LookInside TV UIKit in the app list to inspect its views.",
                symbolName: "cursorarrow.rays",
                symbolTint: .systemPurple
            ),
        ])
    }

    private func makeDemosView() -> UIView {
        let titleLabel = UILabel(
            text: "Demos",
            font: .preferredFont(forTextStyle: .headline),
            color: DemoPalette.primaryLabel
        )
        let buttonsStackView = UIStackView(axis: .horizontal, spacing: DemoMetrics.shelfSpacing, arrangedSubviews: [
            makeDemoButton(.music, symbolName: "music.note", tint: .systemPink, title: "Music", subtitle: "Layers and media shelves"),
            makeDemoButton(.feed, symbolName: "newspaper.fill", tint: .systemOrange, title: "Feed", subtitle: "Monograms and post cards"),
            makeDemoButton(.controls, symbolName: "switch.2", tint: .systemGray, title: "Controls", subtitle: "The tvOS UIKit controls"),
        ])
        return UIStackView(axis: .vertical, spacing: 20, alignment: .leading, arrangedSubviews: [titleLabel, buttonsStackView])
    }

    private func makeDemoButton(_ tab: DemoTab, symbolName: String, tint: UIColor, title: String, subtitle: String) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.image = ArtworkImage.symbolTile(symbolName: symbolName, tint: tint, side: 72)
        configuration.imagePlacement = .top
        configuration.imagePadding = 16
        configuration.title = title
        configuration.subtitle = subtitle
        configuration.titleAlignment = .leading
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 28, leading: 28, bottom: 28, trailing: 28)

        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.tabBarController?.selectedIndex = tab.rawValue
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        // Three of these sit beside the 720-point introduction column inside
        // the 1760-point safe area.
        button.widthAnchor.constraint(equalToConstant: 280).isActive = true
        return button
    }
}
