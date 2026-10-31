import SwiftUI

/// The first tab: what this app is for, how to connect LookInside, the live
/// license state, and a shortcut to each demo.
///
/// Laid out in two columns so it fits on one screen: nothing on the left can
/// take focus, and a screen that only scrolls by moving focus would never
/// reveal it.
struct WelcomeView: View {
    @Binding var selectedTab: DemoTab
    @State private var isLicensed = LookInsideServerRuntime.isLicensed

    var body: some View {
        HStack(alignment: .top, spacing: 80) {
            VStack(alignment: .leading, spacing: 40) {
                header
                statusPanel
            }
            .frame(width: 720, alignment: .leading)

            VStack(alignment: .leading, spacing: 40) {
                stepsPanel
                demoButtons
            }
            .focusSection()
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            // Polled as well as observed: the notification only fires on a
            // change, and the server may have verified before this view
            // appeared.
            while !Task.isCancelled {
                refreshLicenseState()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .lookInsideServerLicenseStateDidChange) {
                refreshLicenseState()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            SymbolTile(symbolName: "square.3.layers.3d", tint: .accentColor, side: 120)
                .padding(.bottom, 8)
            Text("LookInside TV")
                .font(.title2.weight(.bold))
            Text("Open LookInside on your Mac and choose this app to explore its live view hierarchy.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Status")
                .font(.headline)
            HStack {
                Text("License")
                Spacer()
                Circle()
                    .fill(isLicensed ? Color.green : Color.secondary.opacity(0.5))
                    .frame(width: 16, height: 16)
                Text(isLicensed ? "Verified" : "Not verified")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Simulator")
                Spacer()
                Text("TCP loopback · 47164–47169")
                    .foregroundStyle(.secondary)
            }
            Text("LookInside verifies its license each time it connects. SwiftUI views appear in the inspector once it is verified.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .demoPanel()
    }

    private var stepsPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Get Started")
                .font(.headline)
            StepRow(
                symbolName: "arrow.down",
                tint: .blue,
                title: "Install LookInside",
                subtitle: "Download it on your Mac from lookinside-app.com."
            )
            StepRow(
                symbolName: "play.fill",
                tint: .green,
                title: "Run this app",
                subtitle: "In the Apple TV simulator on the same Mac."
            )
            StepRow(
                symbolName: "cursorarrow.rays",
                tint: .purple,
                title: "Choose it in LookInside",
                subtitle: "Select LookInside TV in the app list to inspect its views."
            )
        }
        .demoPanel()
    }

    private var demoButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Demos")
                .font(.headline)
            HStack(spacing: DemoMetrics.shelfSpacing) {
                DemoButton(symbolName: "music.note", tint: .pink, title: "Music", subtitle: "Artwork, transport controls and two shelves") {
                    selectedTab = .music
                }
                DemoButton(symbolName: "newspaper.fill", tint: .orange, title: "Feed", subtitle: "Stories and post cards") {
                    selectedTab = .feed
                }
            }
        }
    }

    private func refreshLicenseState() {
        let latestValue = LookInsideServerRuntime.isLicensed
        if latestValue != isLicensed {
            isLicensed = latestValue
        }
    }
}

private struct StepRow: View {
    let symbolName: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 24) {
            SymbolTile(symbolName: symbolName, tint: tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A large card that switches to one of the demo tabs.
private struct DemoButton: View {
    let symbolName: String
    let tint: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                SymbolTile(symbolName: symbolName, tint: tint, side: 72)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(28)
            .frame(width: 400, height: 280, alignment: .topLeading)
        }
        .buttonStyle(.card)
    }
}
