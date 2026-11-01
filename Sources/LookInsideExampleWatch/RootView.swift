import SwiftUI

/// The demos, by the name the `-demo` launch argument takes. Launched with
/// `-demo Controls`, the app opens that demo straight away, for screenshots
/// and checks that cannot tap.
enum Demo: String, CaseIterable, Hashable {
    case nowPlaying = "NowPlaying"
    case playlists = "Playlists"
    case feed = "Feed"
    case controls = "Controls"

    static var launchArgument: Demo? {
        UserDefaults.standard.string(forKey: "demo").flatMap(Demo.init(rawValue:))
    }
}

/// The app's one navigation stack: what the app is for and the license state
/// on top, then a row for each demo.
///
/// Every screen here is SwiftUI on top of watchOS's own UIKit: the list is a
/// PepperUICore collection view, the stack a PepperUICore navigation
/// controller. LookInside shows both layers.
struct RootView: View {
    @State private var path: [Demo] = Demo.launchArgument.map { [$0] } ?? []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    WelcomeRow()
                }
                Section("Demos") {
                    NavigationLink(value: Demo.nowPlaying) {
                        Label("Now Playing", systemImage: "play.circle.fill")
                    }
                    NavigationLink(value: Demo.playlists) {
                        Label("Playlists", systemImage: "music.note.list")
                    }
                    NavigationLink(value: Demo.feed) {
                        Label("Feed", systemImage: "text.bubble.fill")
                    }
                    NavigationLink(value: Demo.controls) {
                        Label("Controls", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("LookInside")
            .navigationDestination(for: Demo.self) { demo in
                switch demo {
                case .nowPlaying: NowPlayingView(track: MusicTrack.queue[0])
                case .playlists: PlaylistsView()
                case .feed: FeedView()
                case .controls: ControlsView()
                }
            }
        }
    }
}

/// The app's purpose and the live license state.
struct WelcomeRow: View {
    @State private var isLicensed = LookInsideServerRuntime.isLicensed

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                SymbolTile(symbolName: "square.3.layers.3d", tint: .accentColor, side: 32)
                Text("LookInside Watch")
                    .font(.headline)
            }
            Text("Choose this app in LookInside on your Mac.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Circle()
                    .fill(isLicensed ? Color.green : Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(isLicensed ? "License verified" : "License not verified")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task {
            // Polled as well as observed: the notification only fires on a
            // change, and the server may have verified before this row
            // appeared.
            while !Task.isCancelled {
                isLicensed = LookInsideServerRuntime.isLicensed
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .lookInsideServerLicenseStateDidChange) {
                isLicensed = LookInsideServerRuntime.isLicensed
            }
        }
    }
}
