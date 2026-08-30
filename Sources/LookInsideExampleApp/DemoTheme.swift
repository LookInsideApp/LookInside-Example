import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

enum DemoTheme {
    static let cardCorner: CGFloat = 18
    static let bubbleCorner: CGFloat = 18
    static let contentMaxWidth: CGFloat = 720
    static let chatContentMaxWidth: CGFloat = 820

    static var groupedBackground: Color {
        #if canImport(UIKit)
            Color(uiColor: .systemGroupedBackground)
        #else
            Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var secondaryGroupedBackground: Color {
        #if canImport(UIKit)
            Color(uiColor: .secondarySystemGroupedBackground)
        #else
            Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var separator: Color {
        #if canImport(UIKit)
            Color(uiColor: .separator)
        #else
            Color(nsColor: .separatorColor)
        #endif
    }
}

struct AvatarBadge: View {
    let initials: String
    let tint: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.85), tint.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
    }
}

extension Color {
    static func deterministicTint(for seed: String) -> Color {
        let palette: [Color] = [
            .blue, .purple, .pink, .orange, .green, .teal, .indigo, .mint, .cyan,
        ]
        let hash = abs(seed.hashValue)
        return palette[hash % palette.count]
    }
}

extension View {
    func demoCardBackground(corner: CGFloat = DemoTheme.cardCorner) -> some View {
        background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(DemoTheme.secondaryGroupedBackground)
        )
    }

    func demoContentWidth(_ maxWidth: CGFloat = DemoTheme.contentMaxWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func demoOnChange(of value: some Equatable, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, *) {
            onChange(of: value) { _, _ in action() }
        } else {
            onChange(of: value) { _ in action() }
        }
    }
}
