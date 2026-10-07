import AppKit

/// A titled, rounded group of rows separated by inset hairlines — the grouped
/// form look of System Settings, built from a plain `NSStackView` inside an
/// `NSBox`.
final class FormSectionView: NSView {
    init(title: String?, footer: String? = nil, rows: [NSView]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let rowsStackView = NSStackView(orientation: .vertical, spacing: 0, alignment: .leading)
        for (rowIndex, rowView) in rows.enumerated() {
            if rowIndex > 0 {
                let hairlineView = HairlineView()
                rowsStackView.addArrangedSubview(hairlineView)
                NSLayoutConstraint.activate([
                    hairlineView.leadingAnchor.constraint(equalTo: rowsStackView.leadingAnchor, constant: 12),
                    hairlineView.trailingAnchor.constraint(equalTo: rowsStackView.trailingAnchor, constant: -12),
                ])
            }
            rowsStackView.addArrangedSubview(rowView)
            rowView.widthAnchor.constraint(equalTo: rowsStackView.widthAnchor).isActive = true
        }

        let cardBoxView = CardBoxView(cornerRadius: 10)
        if let cardContentView = cardBoxView.contentView {
            cardContentView.addSubview(rowsStackView)
            rowsStackView.pinEdges(to: cardContentView)
        }

        var sectionViews: [NSView] = []
        if let title {
            sectionViews.append(NSTextField.demoLabel(
                title,
                font: .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
                color: DemoPalette.primaryLabel
            ))
        }
        sectionViews.append(cardBoxView)
        if let footer {
            sectionViews.append(NSTextField.demoLabel(
                footer,
                font: .preferredFont(forTextStyle: .caption1),
                color: DemoPalette.secondaryLabel,
                maximumNumberOfLines: 0
            ))
        }

        let sectionStackView = NSStackView(
            orientation: .vertical,
            spacing: 8,
            alignment: .leading,
            views: sectionViews
        )
        addSubview(sectionStackView)
        sectionStackView.pinEdges(to: self)

        for sectionView in sectionViews {
            let horizontalInset: CGFloat = sectionView === cardBoxView ? 0 : 4
            NSLayoutConstraint.activate([
                sectionView.leadingAnchor.constraint(equalTo: sectionStackView.leadingAnchor, constant: horizontalInset),
                sectionView.trailingAnchor.constraint(equalTo: sectionStackView.trailingAnchor, constant: -horizontalInset),
            ])
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// One form row: an optional symbol tile, a title with an optional secondary
/// line, and a trailing accessory view.
final class FormRowView: NSView {
    private var clickHandler: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        symbolName: String? = nil,
        symbolTint: NSColor = DemoPalette.accent,
        accessory: NSView? = nil,
        onClick: (() -> Void)? = nil
    ) {
        clickHandler = onClick
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var rowViews: [NSView] = []
        if let symbolName {
            rowViews.append(SymbolTileView(symbolName: symbolName, tint: symbolTint))
        }

        let titleLabel = NSTextField.demoLabel(
            title,
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.primaryLabel
        )
        var textViews: [NSView] = [titleLabel]
        if let subtitle {
            textViews.append(NSTextField.demoLabel(
                subtitle,
                font: .preferredFont(forTextStyle: .caption1),
                color: DemoPalette.secondaryLabel,
                maximumNumberOfLines: 0
            ))
        }
        let textColumnStackView = NSStackView(
            orientation: .vertical,
            spacing: 2,
            alignment: .leading,
            views: textViews
        )
        textColumnStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textColumnStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rowViews.append(textColumnStackView)
        rowViews.append(NSView.flexibleSpacer())

        if let accessory {
            accessory.setContentCompressionResistancePriority(.required, for: .horizontal)
            rowViews.append(accessory)
        }
        if onClick != nil {
            let chevronImageView = NSImageView()
            chevronImageView.translatesAutoresizingMaskIntoConstraints = false
            chevronImageView.image = NSImage.demoSymbol("chevron.right", pointSize: 11, weight: .semibold)
            chevronImageView.contentTintColor = DemoPalette.tertiaryLabel
            rowViews.append(chevronImageView)
        }

        let rowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: rowViews
        )
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self, insets: NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true

        if onClick != nil {
            addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleClick)))
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleClick() {
        clickHandler?()
    }
}

/// A full-width row for content that needs the whole width of a form
/// section, such as a text view or a banner.
final class FormContentRowView: NSView {
    init(contentView: NSView) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.pinEdges(to: self, insets: NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A rounded, filled square holding a white SF Symbol — the icon tile System
/// Settings shows beside each row.
final class SymbolTileView: GradientView {
    init(symbolName: String, tint: NSColor, side: CGFloat = 24, pointSize: CGFloat = 12) {
        super.init(cornerRadius: side * 0.26)
        setColors([tint, tint.withAlphaComponent(0.78)])

        let symbolImageView = NSImageView()
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.image = NSImage.demoSymbol(symbolName, pointSize: pointSize, weight: .semibold)
        symbolImageView.contentTintColor = .white
        addSubview(symbolImageView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
            symbolImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

extension NSStackView {
    /// A horizontal run of controls, used as the trailing accessory of a
    /// form row.
    static func controlRow(_ views: [NSView], spacing: CGFloat = 8) -> NSStackView {
        NSStackView(orientation: .horizontal, spacing: spacing, alignment: .centerY, views: views)
    }
}
