import Combine
import SwiftUI

struct RootView: View {
    @State private var selectedTab: DemoTab = .welcome

    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomeView(selectedTab: $selectedTab)
                .tabItem { Label("Welcome", systemImage: "hand.wave") }
                .tag(DemoTab.welcome)

            MusicPlayerView()
                .tabItem { Label("Music", systemImage: "music.note") }
                .tag(DemoTab.music)

            SocialFeedView()
                .tabItem { Label("Feed", systemImage: "newspaper") }
                .tag(DemoTab.feed)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                .tag(DemoTab.chat)
        }
    }
}

enum DemoTab: Hashable {
    case welcome
    case music
    case feed
    case chat
}

/// The first tab: what this app is for, how to connect LookInside, the live
/// licence state, and a shortcut to every demo.
private struct WelcomeView: View {
    @Binding var selectedTab: DemoTab
    @State private var isLicensed: Bool = LookInsideServerRuntime.isLicensed
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    WelcomeHeader()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Get Started") {
                    WelcomeRow(
                        symbolName: "arrow.down",
                        tint: .blue,
                        title: "Install LookInside",
                        subtitle: "Download it on your Mac from lookinside-app.com."
                    )
                    WelcomeRow(
                        symbolName: "play.fill",
                        tint: .green,
                        title: "Run this app",
                        subtitle: "In the Simulator, on your Mac, or on a device connected by USB."
                    )
                    WelcomeRow(
                        symbolName: "cursorarrow.rays",
                        tint: .purple,
                        title: "Choose it in LookInside",
                        subtitle: "Select LookInside Example in the app list to inspect its views."
                    )
                }

                Section {
                    LabeledContent("License") {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isLicensed ? Color.green : Color.secondary.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(isLicensed ? "Verified" : "Not verified")
                        }
                    }
                    LabeledContent("Simulator", value: "TCP loopback · 47164–47169")
                    LabeledContent("Device", value: "USB · 47175–47179")
                } header: {
                    Text("Status")
                } footer: {
                    Text("LookInside verifies its license each time it connects. SwiftUI views appear in the inspector once it is verified.")
                }

                Section("Demos") {
                    demoRow(.music, symbolName: "music.note", tint: .pink, title: "Music", subtitle: "Stacks, sliders, and animated artwork")
                    demoRow(.feed, symbolName: "newspaper.fill", tint: .orange, title: "Feed", subtitle: "A lazy stack of cards with a story strip")
                    demoRow(.chat, symbolName: "bubble.left.and.bubble.right.fill", tint: .green, title: "Chat", subtitle: "A split view with a searchable list")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Welcome")
            .demoInlineNavigationTitle()
            .onReceive(refreshTimer) { _ in
                let value = LookInsideServerRuntime.isLicensed
                if value != isLicensed {
                    isLicensed = value
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .LookInsideServerLicenseStateDidChange)) { _ in
                isLicensed = LookInsideServerRuntime.isLicensed
            }
        }
    }

    private func demoRow(_ tab: DemoTab, symbolName: String, tint: Color, title: String, subtitle: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack {
                WelcomeRow(symbolName: symbolName, tint: tint, title: title, subtitle: subtitle)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct WelcomeHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            SymbolTile(symbolName: "square.3.layers.3d", tint: .accentColor, side: 72)
                .padding(.bottom, 10)
            Text("LookInside Example")
                .font(.title.weight(.bold))
            Text("Open LookInside on your Mac and choose this app to explore its live view hierarchy.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct WelcomeRow: View {
    let symbolName: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            SymbolTile(symbolName: symbolName, tint: tint, side: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

private extension Notification.Name {
    static let LookInsideServerLicenseStateDidChange = Notification.Name("LookInsideServerLicenseStateDidChangeNotification")
}
