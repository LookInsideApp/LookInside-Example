import UIKit

/// The first tab: what this app is for, how to connect LookInside, the live
/// licence state, and a shortcut to every demo.
///
/// An inset-grouped table with a hand-built header view. The licence row
/// polls `LookInsideServer.isLicensed` once a second and also listens for the
/// server's change notification.
final class WelcomeViewController: UIViewController {
    /// The tabs the Demos rows switch to, in tab bar order.
    enum DemoTab: Int {
        case music = 1
        case feed
        case chat
        case controls
    }

    private enum Row {
        case step(symbolName: String, tint: UIColor, title: String, subtitle: String)
        case licenseState
        case value(title: String, value: String)
        case demo(DemoTab, symbolName: String, tint: UIColor, title: String, subtitle: String)
    }

    private struct Section {
        let header: String?
        let footer: String?
        let rows: [Row]
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var refreshTimer: Timer?
    private var isLicensed = LookInsideServerRuntime.isLicensed

    private let sections: [Section] = [
        Section(
            header: "Get Started",
            footer: nil,
            rows: [
                .step(
                    symbolName: "arrow.down",
                    tint: .systemBlue,
                    title: "Install LookInside",
                    subtitle: "Download it on your Mac from lookinside-app.com."
                ),
                .step(
                    symbolName: "play.fill",
                    tint: .systemGreen,
                    title: "Run this app",
                    subtitle: "In the Simulator, or on a device connected to your Mac by USB."
                ),
                .step(
                    symbolName: "cursorarrow.rays",
                    tint: .systemPurple,
                    title: "Choose it in LookInside",
                    subtitle: "Select LookInside UIKit in the app list to inspect its views."
                ),
            ]
        ),
        Section(
            header: "Status",
            footer: "LookInside verifies its license each time it connects to this app.",
            rows: [
                .licenseState,
                .value(title: "Simulator", value: "TCP loopback · 47164–47169"),
                .value(title: "Device", value: "USB · 47175–47179"),
            ]
        ),
        Section(
            header: "Demos",
            footer: nil,
            rows: [
                .demo(.music, symbolName: "music.note", tint: .systemPink, title: "Music", subtitle: "Scroll views, stacks, and layers"),
                .demo(.feed, symbolName: "newspaper.fill", tint: .systemOrange, title: "Feed", subtitle: "A compositional collection view"),
                .demo(.chat, symbolName: "bubble.left.and.bubble.right.fill", tint: .systemGreen, title: "Chat", subtitle: "A split view with a searchable list"),
                .demo(.controls, symbolName: "slider.horizontal.3", tint: .systemGray, title: "Controls", subtitle: "Every standard UIKit control"),
            ]
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // The navigation item only: setting `title` would also rename the tab.
        navigationItem.title = "Welcome"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DemoPalette.groupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.register(LicenseStateCell.self, forCellReuseIdentifier: LicenseStateCell.reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlainCell")
        tableView.tableHeaderView = WelcomeHeaderView()
        view.addSubview(tableView)
        tableView.pinEdges(to: view)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(licenseStateDidChange),
            name: Notification.Name("LookInsideServerLicenseStateDidChangeNotification"),
            object: nil
        )
    }

    /// Table header views do not size themselves; fit the header to the
    /// table's width on every layout pass.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let headerView = tableView.tableHeaderView else { return }
        let fittingSize = headerView.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        guard headerView.frame.size != fittingSize else { return }
        headerView.frame.size = fittingSize
        tableView.tableHeaderView = headerView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshLicenseState()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshLicenseState()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    @objc
    private func licenseStateDidChange() {
        refreshLicenseState()
    }

    private func refreshLicenseState() {
        let latestValue = LookInsideServerRuntime.isLicensed
        guard latestValue != isLicensed else { return }
        isLicensed = latestValue
        guard let sectionIndex = sections.firstIndex(where: { section in
            section.rows.contains {
                if case .licenseState = $0 {
                    true
                } else {
                    false
                }
            }
        }) else { return }
        tableView.reloadSections(IndexSet(integer: sectionIndex), with: .none)
    }
}

extension WelcomeViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .licenseState:
            let cell = tableView.dequeueReusableCell(withIdentifier: LicenseStateCell.reuseIdentifier, for: indexPath)
            (cell as? LicenseStateCell)?.configure(isLicensed: isLicensed)
            return cell

        case let .step(symbolName, tint, title, subtitle):
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)
            cell.contentConfiguration = Self.subtitleConfiguration(symbolName: symbolName, tint: tint, title: title, subtitle: subtitle)
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell

        case let .value(title, value):
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = title
            contentConfiguration.secondaryText = value
            cell.contentConfiguration = contentConfiguration
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell

        case let .demo(_, symbolName, tint, title, subtitle):
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)
            cell.contentConfiguration = Self.subtitleConfiguration(symbolName: symbolName, tint: tint, title: title, subtitle: subtitle)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        }
    }

    private static func subtitleConfiguration(
        symbolName: String,
        tint: UIColor,
        title: String,
        subtitle: String
    ) -> UIListContentConfiguration {
        var contentConfiguration = UIListContentConfiguration.subtitleCell()
        contentConfiguration.image = .symbolTile(symbolName, tint: tint)
        contentConfiguration.text = title
        contentConfiguration.secondaryText = subtitle
        contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
        contentConfiguration.secondaryTextProperties.color = DemoPalette.secondaryLabel
        contentConfiguration.textToSecondaryTextVerticalPadding = 2
        contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        return contentConfiguration
    }
}

extension WelcomeViewController: UITableViewDelegate {
    func tableView(_: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case .demo = sections[indexPath.section].rows[indexPath.row] {
            true
        } else {
            false
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard case let .demo(tab, _, _, _, _) = sections[indexPath.section].rows[indexPath.row] else { return }
        tabBarController?.selectedIndex = tab.rawValue
    }
}

/// The hero above the table: an icon tile, the app name and one line on
/// what to do with it.
private final class WelcomeHeaderView: UIView {
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 200))

        let iconTileView = SymbolTileView(symbolName: "square.3.layers.3d", tint: DemoPalette.accent, side: 72, pointSize: 34)
        iconTileView.layer.cornerRadius = 18

        let titleLabel = UILabel(
            text: "LookInside Example",
            font: .preferredFont(forTextStyle: .title1).withWeight(.bold),
            color: DemoPalette.primaryLabel,
            alignment: .center
        )
        titleLabel.adjustsFontForContentSizeCategory = true
        let subtitleLabel = UILabel(
            text: "Open LookInside on your Mac and choose this app to explore its live view hierarchy.",
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.secondaryLabel,
            alignment: .center,
            numberOfLines: 0
        )
        subtitleLabel.adjustsFontForContentSizeCategory = true

        let columnStackView = UIStackView(
            axis: .vertical,
            spacing: 6,
            alignment: .center,
            arrangedSubviews: [iconTileView, titleLabel, subtitleLabel]
        )
        columnStackView.setCustomSpacing(16, after: iconTileView)
        addSubview(columnStackView)

        NSLayoutConstraint.activate([
            columnStackView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            columnStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            columnStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            columnStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 440),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The licence row, built by hand so the tile, the label, the status dot and
/// the value are separate inspectable subviews.
private final class LicenseStateCell: UITableViewCell {
    static let reuseIdentifier = "LicenseStateCell"

    private let indicatorView = UIView()
    private let titleLabel = UILabel(text: "License", font: .preferredFont(forTextStyle: .body), color: DemoPalette.primaryLabel)
    private let valueLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .body), color: DemoPalette.secondaryLabel, alignment: .right)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.layer.cornerRadius = 4

        let valueStackView = UIStackView(
            axis: .horizontal,
            spacing: 6,
            alignment: .center,
            arrangedSubviews: [indicatorView, valueLabel]
        )
        valueStackView.setContentHuggingPriority(.required, for: .horizontal)

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [titleLabel, UIView.flexibleSpacer(), valueStackView]
        )
        contentView.addSubview(rowStackView)
        rowStackView.pinEdges(to: contentView.layoutMarginsGuide)

        NSLayoutConstraint.activate([
            indicatorView.widthAnchor.constraint(equalToConstant: 8),
            indicatorView.heightAnchor.constraint(equalToConstant: 8),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isLicensed: Bool) {
        indicatorView.backgroundColor = isLicensed ? .systemGreen : DemoPalette.tertiaryLabel
        valueLabel.text = isLicensed ? "Verified" : "Not verified"
    }
}
