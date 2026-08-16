import UIKit

extension DemoTint {
    var color: UIColor {
        switch self {
        case .blue: .systemBlue
        case .purple: .systemPurple
        case .pink: .systemPink
        case .orange: .systemOrange
        case .green: .systemGreen
        case .teal: .systemTeal
        case .indigo: .systemIndigo
        case .mint: .systemMint
        case .cyan: .systemCyan
        case .black: .black
        }
    }
}

enum DemoPalette {
    static let accent = UIColor.systemBlue

    static var groupedBackground: UIColor {
        .systemGroupedBackground
    }

    static var cardBackground: UIColor {
        .secondarySystemGroupedBackground
    }

    static var separator: UIColor {
        .separator
    }

    static var primaryLabel: UIColor {
        .label
    }

    static var secondaryLabel: UIColor {
        .secondaryLabel
    }

    static var tertiaryLabel: UIColor {
        .tertiaryLabel
    }
}

enum DemoMetrics {
    static let cardCornerRadius: CGFloat = 18
    static let bubbleCornerRadius: CGFloat = 18
    static let contentMaximumWidth: CGFloat = 640
    static let chatContentMaximumWidth: CGFloat = 820
}
