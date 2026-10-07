import AppKit

/// The first screen: what this app is for, how to connect LookInside, the
/// live licence state, and a shortcut to every demo.
///
/// The licence state is polled once a second and also refreshed on the
/// server's change notification.
final class WelcomeViewController: NSViewController {
    private let licenseIndicatorView = CardBoxView(cornerRadius: 4, fillColor: .systemGreen)
    private let licenseValueLabel = NSTextField.demoLabel(
        font: .preferredFont(forTextStyle: .body),
        color: DemoPalette.primaryLabel
    )

    private var refreshTimer: Timer?
    private var isLicensed = LookInsideServerRuntime.isLicensed

    /// Called when a demo row is clicked.
    var onSelectDestination: ((DemoDestination) -> Void)?

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 28,
            alignment: .leading,
            views: [
                makeHeader(),
                makeGetStartedSection(),
                makeStatusSection(),
                makeDemosSection(),
            ]
        )
        for sectionView in columnStackView.arrangedSubviews {
            sectionView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor).isActive = true
        }
        NSScrollView.installCenteredColumn(columnStackView, in: containerView, maximumWidth: 600, verticalInset: 32)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyLicenseState()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(licenseStateDidChange),
            name: Notification.Name("LookInsideServerLicenseStateDidChangeNotification"),
            object: nil
        )
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshLicenseState()
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Sections

    private func makeHeader() -> NSView {
        let iconTileView = SymbolTileView(
            symbolName: "square.3.layers.3d",
            tint: DemoPalette.accent,
            side: 64,
            pointSize: 30
        )

        let titleLabel = NSTextField.demoLabel(
            "LookInside Example",
            font: .systemFont(ofSize: 26, weight: .bold),
            color: DemoPalette.primaryLabel
        )
        let subtitleLabel = NSTextField.demoLabel(
            "Open LookInside on this Mac and choose this app to explore its live view hierarchy.",
            font: .preferredFont(forTextStyle: .title3),
            color: DemoPalette.secondaryLabel,
            maximumNumberOfLines: 0
        )

        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 4,
            alignment: .leading,
            views: [titleLabel, subtitleLabel]
        )
        textColumnStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return NSStackView(
            orientation: .horizontal,
            spacing: 16,
            alignment: .centerY,
            views: [iconTileView, textColumnStackView]
        )
    }

    private func makeGetStartedSection() -> NSView {
        FormSectionView(title: "Get Started", rows: [
            FormRowView(
                title: "Install LookInside",
                subtitle: "Download it from lookinside-app.com.",
                symbolName: "arrow.down",
                symbolTint: .systemBlue
            ),
            FormRowView(
                title: "Keep this app running",
                subtitle: "LookInside finds it automatically while it runs.",
                symbolName: "play.fill",
                symbolTint: .systemGreen
            ),
            FormRowView(
                title: "Choose it in LookInside",
                subtitle: "Select LookInside AppKit in the app list to inspect its views.",
                symbolName: "cursorarrow.rays",
                symbolTint: .systemPurple
            ),
        ])
    }

    /// Key–value rows in an `NSGridView`, so the labels share one column
    /// width and the values line up on a common leading edge.
    ///
    /// `rowAlignment` is set instead of per-cell `yPlacement` on purpose: with
    /// an alignment other than `.none`, AppKit discards `cell.yPlacement`
    /// entirely. The explicit `needsUpdateConstraints` is also required —
    /// the spacing and placement setters do not invalidate on their own.
    private func makeStatusSection() -> NSView {
        NSLayoutConstraint.activate([
            licenseIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            licenseIndicatorView.heightAnchor.constraint(equalToConstant: 8),
        ])
        let licenseValueStackView = NSStackView.controlRow([licenseIndicatorView, licenseValueLabel], spacing: 6)

        let gridView = NSGridView(numberOfColumns: 2, rows: 0)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 10
        gridView.columnSpacing = 16
        gridView.xPlacement = .leading
        gridView.rowAlignment = .firstBaseline
        gridView.needsUpdateConstraints = true

        let rows: [(title: String, value: NSView)] = [
            ("License", licenseValueStackView),
            ("Connection", makeGridValueLabel("TCP loopback")),
            ("Ports", makeGridValueLabel("47164–47169")),
        ]
        for row in rows {
            gridView.addRow(with: [
                NSTextField.demoLabel(row.title, font: .preferredFont(forTextStyle: .body), color: DemoPalette.secondaryLabel),
                row.value,
            ])
        }
        gridView.column(at: 0).width = 96

        return FormSectionView(
            title: "Status",
            footer: "LookInside verifies its license each time it connects to this app.",
            rows: [FormContentRowView(contentView: gridView)]
        )
    }

    private func makeGridValueLabel(_ text: String) -> NSTextField {
        NSTextField.demoLabel(text, font: .preferredFont(forTextStyle: .body), color: DemoPalette.primaryLabel)
    }

    private func makeDemosSection() -> NSView {
        let demoRows: [(destination: DemoDestination, subtitle: String, tint: NSColor)] = [
            (.music, "Stack views, sliders, and Core Animation layers", .systemPink),
            (.feed, "A view-based table with automatic row heights", .systemOrange),
            (.chat, "A nested split view with a searchable list", .systemGreen),
            (.controls, "Every standard AppKit control in one place", .systemGray),
        ]
        return FormSectionView(title: "Demos", rows: demoRows.map { demoRow in
            FormRowView(
                title: demoRow.destination.title,
                subtitle: demoRow.subtitle,
                symbolName: demoRow.destination.filledSymbolName,
                symbolTint: demoRow.tint,
                onClick: { [weak self] in
                    self?.onSelectDestination?(demoRow.destination)
                }
            )
        })
    }

    // MARK: - Licence state

    @objc
    private func licenseStateDidChange() {
        refreshLicenseState()
    }

    func refreshLicenseState() {
        let latestValue = LookInsideServerRuntime.isLicensed
        guard latestValue != isLicensed else { return }
        isLicensed = latestValue
        applyLicenseState()
    }

    private func applyLicenseState() {
        licenseIndicatorView.fillColor = isLicensed ? .systemGreen : DemoPalette.tertiaryLabel
        licenseValueLabel.stringValue = isLicensed ? "Verified" : "Not verified"
    }
}
