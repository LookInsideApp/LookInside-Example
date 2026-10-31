import SwiftUI

/// The top-level tab bar. On Apple TV it sits along the top of the screen and
/// takes focus first; swiping down moves focus into the selected tab.
struct RootView: View {
    @State private var selectedTab: DemoTab = .welcome

    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomeView(selectedTab: $selectedTab)
                .tabItem { Label("Welcome", systemImage: "hand.wave") }
                .tag(DemoTab.welcome)

            MusicView()
                .tabItem { Label("Music", systemImage: "music.note") }
                .tag(DemoTab.music)

            FeedView()
                .tabItem { Label("Feed", systemImage: "newspaper") }
                .tag(DemoTab.feed)
        }
    }
}

enum DemoTab: Hashable {
    case welcome
    case music
    case feed
}
