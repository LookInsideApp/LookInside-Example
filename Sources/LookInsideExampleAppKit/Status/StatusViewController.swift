import AppKit

/// The Status screen: `NSGridView` tables reporting
/// `LookInsideServer.isLicensed`, polled once a second and refreshed on the
/// server's change notification.
final class StatusViewController: NSViewController {
    private let licenseIndicatorView = CardBoxView(cornerRadius: 5, fillColor: .systemGreen)
    private let licenseValueLabel = NSTextField.demoLabel(
        font: .monospacedSystemFont(ofSize: 12, weight: .regular),
        color: DemoPalette.secondaryLabel,
        alignment: .right
    )

    private var refreshTimer: Timer?
    private var isLicensed = LookInsideServerRuntime.isLicensed

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 24,
            alignment: .leading,
            views: [
                makeLicenseSection(),
                makeDemosSection(),
                makeInstructionsSection(),
            ]
        )
        documentView.addSubview(columnStackView)
        containerView.addSubview(scrollView)
        scrollView.pinEdges(to: containerView)

        let clipView = scrollView.contentView
        let preferredWidthConstraint = columnStackView.widthAnchor.constraint(
            equalTo: documentView.widthAnchor,
            constant: -48
        )
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: clipView.widthAnchor),

            columnStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 24),
            columnStackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -24),
            columnStackView.centerXAnchor.constraint(equalTo: documentView.centerXAnchor),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: documentView.leadingAnchor, constant: 24),
            columnStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth),
            preferredWidthConstraint,
        ])
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

    private func makeLicenseSection() -> NSView {
        let indicatorRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [
                licenseIndicatorView,
                NSTextField.demoLabel("isLicensed", font: .preferredFont(forTextStyle: .body), color: DemoPalette.primaryLabel),
            ]
        )
        NSLayoutConstraint.activate([
            licenseIndicatorView.widthAnchor.constraint(equalToConstant: 10),
            licenseIndicatorView.heightAnchor.constraint(equalToConstant: 10),
        ])

        let gridView = makeGridView()
        gridView.addRow(with: [indicatorRowStackView, licenseValueLabel])
        gridView.column(at: 1).xPlacement = .trailing

        let footnoteLabel = NSTextField.demoLabel(
            "Auto-refreshes every second from LookInsideServer.isLicensed.",
            font: .preferredFont(forTextStyle: .caption1),
            color: DemoPalette.secondaryLabel,
            maximumNumberOfLines: 0
        )

        return makeSection(title: "LookInsideServer", contentView: gridView, footnoteView: footnoteLabel)
    }

    private func makeDemosSection() -> NSView {
        let gridView = makeGridView()
        let demoRows: [(symbolName: String, text: String)] = [
            ("play.circle", "Music player · NSStackView + Core Animation"),
            ("square.text.square", "Social feed · view-based NSTableView"),
            ("bubble.left.and.bubble.right", "Chat · nested NSSplitViewController"),
        ]
        for demoRow in demoRows {
            let symbolImageView = NSImageView()
            symbolImageView.translatesAutoresizingMaskIntoConstraints = false
            symbolImageView.image = NSImage.demoSymbol(demoRow.symbolName, pointSize: 14)
            symbolImageView.contentTintColor = DemoPalette.accent
            symbolImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true

            let textLabel = NSTextField.demoLabel(
                demoRow.text,
                font: .preferredFont(forTextStyle: .body),
                color: DemoPalette.primaryLabel
            )
            gridView.addRow(with: [symbolImageView, textLabel])
        }
        gridView.column(at: 0).width = 24

        return makeSection(title: "Demos", contentView: gridView, footnoteView: nil)
    }

    private func makeInstructionsSection() -> NSView {
        let gridView = NSGridView(numberOfColumns: 1, rows: 0)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 8
        gridView.xPlacement = .leading
        gridView.rowAlignment = .firstBaseline
        gridView.needsUpdateConstraints = true

        let instructions = [
            "1. Run this app on your Mac.",
            "2. Launch the LookInside macOS host.",
            "3. The host auto-discovers this app via Peertalk on ports 47164–47169.",
        ]
        for instruction in instructions {
            gridView.addRow(with: [
                NSTextField.demoLabel(
                    instruction,
                    font: .preferredFont(forTextStyle: .body),
                    color: DemoPalette.primaryLabel,
                    maximumNumberOfLines: 0
                ),
            ])
        }

        return makeSection(title: "How to use", contentView: gridView, footnoteView: nil)
    }

    /// Two-column grid with leading text and baseline-aligned rows.
    ///
    /// `rowAlignment` is set instead of per-cell `yPlacement` on purpose: with
    /// an alignment other than `.none`, AppKit discards `cell.yPlacement`
    /// entirely. The explicit `needsUpdateConstraints` is also required —
    /// the spacing and placement setters do not invalidate on their own.
    private func makeGridView() -> NSGridView {
        let gridView = NSGridView(numberOfColumns: 2, rows: 0)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 10
        gridView.columnSpacing = 12
        gridView.xPlacement = .leading
        gridView.rowAlignment = .firstBaseline
        gridView.needsUpdateConstraints = true
        return gridView
    }

    private func makeSection(title: String, contentView: NSView, footnoteView: NSView?) -> NSView {
        let titleLabel = NSTextField.demoLabel(
            title.uppercased(),
            font: .preferredFont(forTextStyle: .caption1).withWeight(.semibold),
            color: DemoPalette.secondaryLabel
        )

        let cardBoxView = CardBoxView()
        cardBoxView.contentView?.addSubview(contentView)
        if let cardContentView = cardBoxView.contentView {
            contentView.pinEdges(
                to: cardContentView,
                insets: NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
            )
        }

        var sectionViews: [NSView] = [titleLabel, cardBoxView]
        if let footnoteView {
            sectionViews.append(footnoteView)
        }

        let sectionStackView = NSStackView(
            orientation: .vertical,
            spacing: 8,
            alignment: .leading,
            views: sectionViews
        )
        for sectionView in sectionViews where sectionView !== titleLabel {
            sectionView.widthAnchor.constraint(equalTo: sectionStackView.widthAnchor).isActive = true
        }
        return sectionStackView
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
        licenseIndicatorView.fillColor = isLicensed ? .systemGreen : DemoPalette.secondaryLabel.withAlphaComponent(0.4)
        licenseValueLabel.stringValue = isLicensed ? "YES" : "NO"
        licenseValueLabel.textColor = isLicensed ? .systemGreen : DemoPalette.secondaryLabel
    }
}
