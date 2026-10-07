import UIKit

/// A titled, rounded group of rows separated by inset hairlines — the
/// inset-grouped look of Settings, built from a plain `UIStackView` inside a
/// `CardView`.
final class FormSectionView: UIView {
    init(title: String?, footer: String? = nil, rows: [UIView]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let rowsStackView = UIStackView(axis: .vertical)
        for (rowIndex, rowView) in rows.enumerated() {
            if rowIndex > 0 {
                let hairlineContainerView = UIView()
                hairlineContainerView.translatesAutoresizingMaskIntoConstraints = false
                let hairlineView = HairlineView()
                hairlineContainerView.addSubview(hairlineView)
                hairlineView.pinEdges(to: hairlineContainerView, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
                rowsStackView.addArrangedSubview(hairlineContainerView)
            }
            rowsStackView.addArrangedSubview(rowView)
        }

        let cardView = CardView(cornerRadius: DemoMetrics.formCornerRadius)
        cardView.addSubview(rowsStackView)
        rowsStackView.pinEdges(to: cardView)

        var sectionViews: [UIView] = []
        if let title {
            let titleLabel = UILabel(
                text: title,
                font: .preferredFont(forTextStyle: .headline),
                color: DemoPalette.primaryLabel
            )
            sectionViews.append(Self.inset(titleLabel))
        }
        sectionViews.append(cardView)
        if let footer {
            let footerLabel = UILabel(
                text: footer,
                font: .preferredFont(forTextStyle: .footnote),
                color: DemoPalette.secondaryLabel,
                numberOfLines: 0
            )
            sectionViews.append(Self.inset(footerLabel))
        }

        let sectionStackView = UIStackView(axis: .vertical, spacing: 8, arrangedSubviews: sectionViews)
        addSubview(sectionStackView)
        sectionStackView.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Lines a header or footer up with the text inside the card.
    private static func inset(_ label: UILabel) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        label.pinEdges(to: containerView, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        return containerView
    }
}

/// One form row: an optional symbol tile, a title with an optional secondary
/// line, and a trailing accessory view.
final class FormRowView: UIView {
    init(
        title: String,
        subtitle: String? = nil,
        symbolName: String? = nil,
        symbolTint: UIColor = DemoPalette.accent,
        accessory: UIView? = nil
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var rowViews: [UIView] = []
        if let symbolName {
            rowViews.append(SymbolTileView(symbolName: symbolName, tint: symbolTint))
        }

        let titleLabel = UILabel(
            text: title,
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.primaryLabel,
            numberOfLines: 0
        )
        var textViews: [UIView] = [titleLabel]
        if let subtitle {
            textViews.append(UILabel(
                text: subtitle,
                font: .preferredFont(forTextStyle: .footnote),
                color: DemoPalette.secondaryLabel,
                numberOfLines: 0
            ))
        }
        let textColumnStackView = UIStackView(axis: .vertical, spacing: 2, arrangedSubviews: textViews)
        textColumnStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textColumnStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rowViews.append(textColumnStackView)

        if let accessory {
            accessory.translatesAutoresizingMaskIntoConstraints = false
            accessory.setContentHuggingPriority(.required, for: .horizontal)
            accessory.setContentCompressionResistancePriority(.required, for: .horizontal)
            rowViews.append(accessory)
        }

        let rowStackView = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, arrangedSubviews: rowViews)
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self, insets: UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16))
        heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A full-width row for content that needs the whole width of a form
/// section, such as a text view or a banner.
final class FormContentRowView: UIView {
    init(contentView: UIView, insets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.pinEdges(to: self, insets: insets)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A rounded, filled square holding a white SF Symbol — the icon tile
/// Settings shows beside each row.
final class SymbolTileView: UIView {
    init(symbolName: String, tint: UIColor, side: CGFloat = 30, pointSize: CGFloat = 15) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = tint
        layer.cornerRadius = side * 0.26
        layer.cornerCurve = .continuous

        let symbolImageView = UIImageView(image: UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        ))
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.tintColor = .white
        symbolImageView.contentMode = .center
        addSubview(symbolImageView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
            symbolImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImage {
    /// A Settings-style icon tile rendered to an image, for list content
    /// configurations that take a `UIImage` rather than a view.
    static func symbolTile(_ symbolName: String, tint: UIColor, side: CGFloat = 30) -> UIImage {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: side * 0.5, weight: .semibold)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let tileSize = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: tileSize).image { _ in
            tint.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: tileSize), cornerRadius: side * 0.26).fill()
            if let symbolImage {
                let symbolOrigin = CGPoint(
                    x: (tileSize.width - symbolImage.size.width) / 2,
                    y: (tileSize.height - symbolImage.size.height) / 2
                )
                symbolImage.draw(at: symbolOrigin)
            }
        }
    }
}
