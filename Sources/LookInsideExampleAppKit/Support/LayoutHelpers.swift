import AppKit

extension NSView {
    func pinEdges(to other: NSView, insets: NSEdgeInsets = NSEdgeInsets()) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom),
        ])
    }

    func pinEdges(to layoutGuide: NSLayoutGuide, insets: NSEdgeInsets = NSEdgeInsets()) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -insets.bottom),
        ])
    }

    static func flexibleSpacer() -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return spacer
    }
}

extension NSTextField {
    /// A non-editable label with the demo's default styling.
    static func demoLabel(
        _ text: String? = nil,
        font: NSFont,
        color: NSColor,
        alignment: NSTextAlignment = .natural,
        maximumNumberOfLines: Int = 1
    ) -> NSTextField {
        let label = NSTextField(labelWithString: text ?? "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
        label.textColor = color
        label.alignment = alignment
        label.maximumNumberOfLines = maximumNumberOfLines
        label.lineBreakMode = maximumNumberOfLines == 1 ? .byTruncatingTail : .byWordWrapping
        label.cell?.wraps = maximumNumberOfLines != 1
        label.cell?.usesSingleLineMode = maximumNumberOfLines == 1
        return label
    }
}

extension NSStackView {
    convenience init(
        orientation: NSUserInterfaceLayoutOrientation,
        spacing: CGFloat = 0,
        alignment: NSLayoutConstraint.Attribute? = nil,
        distribution: NSStackView.Distribution = .fill,
        views: [NSView] = []
    ) {
        self.init(views: views)
        translatesAutoresizingMaskIntoConstraints = false
        self.orientation = orientation
        self.spacing = spacing
        self.distribution = distribution
        if let alignment {
            self.alignment = alignment
        }
    }
}

extension NSImage {
    /// SF Symbol lookup with a point-size / weight configuration applied.
    static func demoSymbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight = .regular) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
    }
}

extension NSButton {
    /// A borderless symbol button, the AppKit stand-in for a plain-styled
    /// SwiftUI `Button` wrapping an `Image(systemName:)`.
    static func demoSymbolButton(
        symbolName: String,
        pointSize: CGFloat,
        weight: NSFont.Weight = .regular,
        target: AnyObject? = nil,
        action: Selector? = nil
    ) -> NSButton {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.image = NSImage.demoSymbol(symbolName, pointSize: pointSize, weight: weight)
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.bezelStyle = .shadowlessSquare
        button.contentTintColor = DemoPalette.secondaryLabel
        button.target = target
        button.action = action
        return button
    }
}

/// A top-left origin view, used as the document view of vertical scroll views
/// so content starts at the top instead of the AppKit default bottom-left.
final class FlippedView: NSView {
    override var isFlipped: Bool {
        true
    }
}

/// A rounded, filled container. `NSBox` owns its own corner radius and fill
/// colour, which keeps this off the backing layer entirely — AppKit
/// continuously re-syncs `layer.cornerRadius` from the view, so a card built by
/// poking the backing layer would lose its corners on the next sync.
final class CardBoxView: NSBox {
    init(cornerRadius: CGFloat = DemoMetrics.cardCornerRadius, fillColor: NSColor = DemoPalette.cardBackground) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        boxType = .custom
        borderWidth = 0
        self.fillColor = fillColor
        self.cornerRadius = cornerRadius
        contentViewMargins = .zero
        titlePosition = .noTitle
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A one-pixel separator line.
final class HairlineView: NSBox {
    init(orientation: NSUserInterfaceLayoutOrientation = .horizontal) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        boxType = .custom
        borderWidth = 0
        fillColor = DemoPalette.separator
        contentViewMargins = .zero
        titlePosition = .noTitle
        switch orientation {
        case .horizontal:
            heightAnchor.constraint(equalToConstant: 1).isActive = true
        case .vertical:
            widthAnchor.constraint(equalToConstant: 1).isActive = true
        @unknown default:
            heightAnchor.constraint(equalToConstant: 1).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
