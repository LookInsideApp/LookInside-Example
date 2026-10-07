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

    /// The fill of grouped boxes and cards: a faint tint over the window
    /// background, the way System Settings draws its grouped forms.
    static var cardBackground: NSColor {
        .quaternarySystemFill
    }

    /// Incoming chat bubbles: opaque so the text stays crisp over any
    /// background.
    static let incomingBubble = NSColor(name: "DemoIncomingBubble") { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark
            ? NSColor(srgbRed: 0.23, green: 0.23, blue: 0.24, alpha: 1)
            : NSColor(srgbRed: 0.91, green: 0.91, blue: 0.92, alpha: 1)
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

extension NSLayoutConstraint.Priority {
    /// Just below `windowSizeStayPut`: strong enough to stretch a content
    /// column to the available width, too weak to resize the window to fit
    /// the column instead.
    static let fillAvailableWidth = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.windowSizeStayPut.rawValue - 10)
}

enum DemoMetrics {
    static let cardCornerRadius: CGFloat = 12
    static let bubbleCornerRadius: CGFloat = 16
    static let contentMaximumWidth: CGFloat = 680
    static let chatContentMaximumWidth: CGFloat = 820
}
