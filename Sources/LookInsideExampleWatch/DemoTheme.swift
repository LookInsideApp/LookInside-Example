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

/// An SF Symbol on a rounded, tinted square.
struct SymbolTile: View {
    let symbolName: String
    let tint: Color
    let side: CGFloat

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: side * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: side * 0.25, style: .continuous))
    }
}

/// A person's initials on a tinted circle.
struct AvatarBadge: View {
    let initials: String
    let tint: DemoTint
    let side: CGFloat

    var body: some View {
        Text(initials)
            .font(.system(size: side * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(tint.color.gradient, in: Circle())
    }
}

extension Notification.Name {
    /// Posted by the server whenever its license state changes.
    static let lookInsideServerLicenseStateDidChange = Notification.Name("LookInsideServerLicenseStateDidChangeNotification")
}
