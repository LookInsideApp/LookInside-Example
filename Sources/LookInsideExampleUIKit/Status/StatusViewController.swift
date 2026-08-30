import UIKit

/// Mirrors the SwiftUI example's Status tab: a grouped table that polls
/// `LookInsideServer.isLicensed` once a second and also listens for the
/// server's change notification.
final class StatusViewController: UIViewController {
    private enum Row {
        case licenseState
        case detail(symbolName: String, text: String)
        case paragraph(String)
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
            header: "LookInsideServer",
            footer: "Auto-refreshes every second from `LookInsideServer.isLicensed`.",
            rows: [.licenseState]
        ),
        Section(
            header: "Demos",
            footer: nil,
            rows: [
                .detail(symbolName: "play.circle", text: "Music player · UIScrollView + UIStackView"),
                .detail(symbolName: "square.text.square", text: "Social feed · UICollectionView"),
                .detail(symbolName: "bubble.left.and.bubble.right", text: "Chat · UISplitViewController"),
                .detail(symbolName: "slider.horizontal.3", text: "Controls · the stock UIKit control gallery"),
            ]
        ),
        Section(
            header: "How to use",
            footer: nil,
            rows: [
                .paragraph("1. Run this app on the iOS Simulator or an iPhone/iPad."),
                .paragraph("2. Launch the LookInside macOS host on the same Mac."),
                .paragraph("3. The host auto-discovers this app via Peertalk on ports 47164–47169 (sim) / 47175–47179 (USB)."),
            ]
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Status"
        view.backgroundColor = DemoPalette.groupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(LicenseStateCell.self, forCellReuseIdentifier: LicenseStateCell.reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlainCell")
        view.addSubview(tableView)
        tableView.pinEdges(to: view)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(licenseStateDidChange),
            name: Notification.Name("LookInsideServerLicenseStateDidChangeNotification"),
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
}

extension StatusViewController: UITableViewDataSource {
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

        case let .detail(symbolName, text):
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = text
            contentConfiguration.image = UIImage(systemName: symbolName)
            cell.contentConfiguration = contentConfiguration
            return cell

        case let .paragraph(text):
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = text
            contentConfiguration.textProperties.numberOfLines = 0
            cell.contentConfiguration = contentConfiguration
            return cell
        }
    }
}

extension StatusViewController: UITableViewDelegate {}

/// The single row that reports the licence state, built by hand so the dot,
/// the label and the monospaced value are three inspectable subviews.
private final class LicenseStateCell: UITableViewCell {
    static let reuseIdentifier = "LicenseStateCell"

    private let indicatorView = UIView()
    private let titleLabel = UILabel(text: "isLicensed", font: .preferredFont(forTextStyle: .body), color: DemoPalette.primaryLabel)
    private let valueLabel = UILabel(text: nil, font: .monospacedSystemFont(ofSize: 15, weight: .regular), color: DemoPalette.secondaryLabel, alignment: .right)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.layer.cornerRadius = 5

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [indicatorView, titleLabel, UIView.flexibleSpacer(), valueLabel]
        )
        contentView.addSubview(rowStackView)
        rowStackView.pinEdges(to: contentView.layoutMarginsGuide)

        NSLayoutConstraint.activate([
            indicatorView.widthAnchor.constraint(equalToConstant: 10),
            indicatorView.heightAnchor.constraint(equalToConstant: 10),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isLicensed: Bool) {
        indicatorView.backgroundColor = isLicensed ? .systemGreen : DemoPalette.secondaryLabel.withAlphaComponent(0.4)
        valueLabel.text = isLicensed ? "YES" : "NO"
        valueLabel.textColor = isLicensed ? .systemGreen : DemoPalette.secondaryLabel
    }
}
