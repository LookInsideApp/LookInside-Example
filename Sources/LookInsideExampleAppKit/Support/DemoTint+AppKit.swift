import AppKit

extension DemoTint {
    var color: NSColor {
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
    static var accent: NSColor {
        .controlAccentColor
    }

    static var windowBackground: NSColor {
        .windowBackgroundColor
    }

    static var cardBackground: NSColor {
        .controlBackgroundColor
    }

    static var separator: NSColor {
        .separatorColor
    }

    static var primaryLabel: NSColor {
        .labelColor
    }

    static var secondaryLabel: NSColor {
        .secondaryLabelColor
    }

    static var tertiaryLabel: NSColor {
        .tertiaryLabelColor
    }
}

enum DemoMetrics {
    static let cardCornerRadius: CGFloat = 12
    static let bubbleCornerRadius: CGFloat = 16
    static let contentMaximumWidth: CGFloat = 640
    static let chatContentMaximumWidth: CGFloat = 820
}
