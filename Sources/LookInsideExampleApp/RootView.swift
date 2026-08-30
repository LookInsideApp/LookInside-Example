import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            MusicPlayerView()
                .tabItem { Label("Music", systemImage: "play.circle.fill") }

            SocialFeedView()
                .tabItem { Label("Feed", systemImage: "square.text.square.fill") }

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }

            StatusView()
                .tabItem { Label("Status", systemImage: "info.circle") }
        }
    }
}

private struct StatusView: View {
    @State private var isLicensed: Bool = LookInsideServerRuntime.isLicensed
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(isLicensed ? Color.green : Color.secondary.opacity(0.4))
                            .frame(width: 10, height: 10)
                        Text("isLicensed")
                        Spacer()
                        Text(isLicensed ? "YES" : "NO")
                            .font(.callout.monospaced())
                            .foregroundStyle(isLicensed ? .green : .secondary)
                    }
                } header: {
                    Text("LookInsideServer")
                } footer: {
                    Text("Auto-refreshes every second from `LookInsideServer.isLicensed`.")
                }

                Section("Demos") {
                    Label("Music player", systemImage: "play.circle")
                    Label("Social feed", systemImage: "square.text.square")
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

                Section("How to use") {
                    Text("1. Run this app on the iOS Simulator, this Mac, or an iPad.")
                    Text("2. Launch the LookInside macOS host on the same Mac.")
                    Text("3. The host auto-discovers this app via Peertalk on ports 47164–47169 (sim) / 47175–47179 (USB).")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Status")
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
}

private extension Notification.Name {
    static let LookInsideServerLicenseStateDidChange = Notification.Name("LookInsideServerLicenseStateDidChangeNotification")
}
