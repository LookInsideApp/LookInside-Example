import SwiftUI

extension DemoTint {
    var color: Color {
        switch self {
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        case .indigo: .indigo
        case .mint: .mint
        case .cyan: .cyan
        case .black: .black
        }
    }
}

enum DemoMetrics {
    /// The vertical gap between the sections of a screen.
    static let sectionSpacing: CGFloat = 56
    /// The gap between neighbouring cards on a shelf.
    static let shelfSpacing: CGFloat = 40
    static let cardCornerRadius: CGFloat = 24
}

/// A titled row of focusable cards that scrolls sideways — the shelf every
/// Apple TV app is built from.
///
/// Focus lifts a card above its neighbours, so the row is not clipped to its
/// bounds and keeps some vertical room for the lifted card.
struct Shelf<Cards: View>: View {
    let title: String
    @ViewBuilder let cards: Cards

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.headline)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: DemoMetrics.shelfSpacing) {
                    cards
                }
                .padding(.vertical, 28)
            }
            .scrollClipDisabled()
        }
        .focusSection()
    }
}

/// A rounded, filled square holding a white SF Symbol — the icon tile
/// Settings shows beside each row.
struct SymbolTile: View {
    let symbolName: String
    let tint: Color
    var side: CGFloat = 56

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: side * 0.46, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: side * 0.26, style: .continuous))
    }
}

/// A circular gradient badge with monogram initials.
struct AvatarBadge: View {
    let initials: String
    let tint: Color
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.9), tint.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 2))
    }
}

/// The rounded panel the Welcome screen groups its rows in.
struct PanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DemoMetrics.cardCornerRadius, style: .continuous))
    }
}

extension View {
    func demoPanel() -> some View {
        modifier(PanelBackground())
    }
}

extension Notification.Name {
    /// Posted by the LookInside server whenever its license state changes.
    static let lookInsideServerLicenseStateDidChange = Notification.Name("LookInsideServerLicenseStateDidChangeNotification")
}
