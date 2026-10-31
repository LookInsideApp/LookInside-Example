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

    /// The fill behind panels and cards. tvOS has no grouped background
    /// colours, so this is a translucent white that reads on both the light
    /// and the dark system background.
    static let panelBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.1)
            : UIColor(white: 1, alpha: 0.7)
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
    static let panelCornerRadius: CGFloat = 24
    static let panelPadding: CGFloat = 32
    /// The vertical gap between the sections of a screen.
    static let sectionSpacing: CGFloat = 48
    /// The gap between neighbouring cards on a shelf.
    static let shelfSpacing: CGFloat = 40
}
