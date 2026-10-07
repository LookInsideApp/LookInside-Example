import AppKit

/// A centred placeholder: a large secondary SF Symbol, a title and one short
/// line of guidance.
final class EmptyStateView: NSView {
    init(symbolName: String, title: String, message: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let symbolImageView = NSImageView()
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.image = NSImage.demoSymbol(symbolName, pointSize: 44, weight: .light)
        symbolImageView.contentTintColor = DemoPalette.tertiaryLabel

        let titleLabel = NSTextField.demoLabel(
            title,
            font: .preferredFont(forTextStyle: .title3).withWeight(.semibold),
            color: DemoPalette.primaryLabel,
            alignment: .center
        )
        let messageLabel = NSTextField.demoLabel(
            message,
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.secondaryLabel,
            alignment: .center,
            maximumNumberOfLines: 0
        )

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 6,
            alignment: .centerX,
            views: [symbolImageView, titleLabel, messageLabel]
        )
        columnStackView.setCustomSpacing(14, after: symbolImageView)
        addSubview(columnStackView)
        columnStackView.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
