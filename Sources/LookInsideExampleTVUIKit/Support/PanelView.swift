import UIKit

/// A rounded, translucent panel with a title above its rows — the grouping
/// the Welcome and Controls screens use.
final class PanelView: UIView {
    init(title: String?, footer: String? = nil, rows: [UIView], rowSpacing: CGFloat = 24) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DemoPalette.panelBackground
        layer.cornerRadius = DemoMetrics.panelCornerRadius
        layer.cornerCurve = .continuous

        var arrangedViews: [UIView] = []
        if let title {
            arrangedViews.append(UILabel(
                text: title,
                font: .preferredFont(forTextStyle: .headline),
                color: DemoPalette.primaryLabel
            ))
        }
        arrangedViews.append(contentsOf: rows)
        if let footer {
            arrangedViews.append(UILabel(
                text: footer,
                font: .preferredFont(forTextStyle: .caption1),
                color: DemoPalette.secondaryLabel,
                numberOfLines: 0
            ))
        }

        let contentStackView = UIStackView(axis: .vertical, spacing: rowSpacing, arrangedSubviews: arrangedViews)
        addSubview(contentStackView)
        let padding = DemoMetrics.panelPadding
        contentStackView.pinEdges(to: self, insets: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// One row inside a panel: an optional symbol tile, a title with an optional
/// secondary line, and a trailing accessory view.
final class PanelRowView: UIView {
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

        var textViews: [UIView] = [UILabel(
            text: title,
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.primaryLabel,
            numberOfLines: 0
        )]
        if let subtitle {
            textViews.append(UILabel(
                text: subtitle,
                font: .preferredFont(forTextStyle: .caption1),
                color: DemoPalette.secondaryLabel,
                numberOfLines: 0
            ))
        }
        let textColumnStackView = UIStackView(axis: .vertical, spacing: 4, arrangedSubviews: textViews)
        textColumnStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textColumnStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rowViews.append(textColumnStackView)

        if let accessory {
            accessory.translatesAutoresizingMaskIntoConstraints = false
            accessory.setContentHuggingPriority(.required, for: .horizontal)
            accessory.setContentCompressionResistancePriority(.required, for: .horizontal)
            rowViews.append(accessory)
        }

        let rowStackView = UIStackView(axis: .horizontal, spacing: 24, alignment: .center, arrangedSubviews: rowViews)
        addSubview(rowStackView)
        rowStackView.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A rounded, filled square holding a white SF Symbol — the icon tile
/// Settings shows beside each row.
final class SymbolTileView: UIView {
    init(symbolName: String, tint: UIColor, side: CGFloat = 56, pointSize: CGFloat = 26) {
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

/// The title above a shelf in a collection view.
final class SectionHeaderView: UICollectionReusableView {
    let titleLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .headline), color: DemoPalette.primaryLabel)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.pinEdges(to: self, insets: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
