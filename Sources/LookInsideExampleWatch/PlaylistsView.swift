import SwiftUI

/// The playlists, each opening the shared track queue.
struct PlaylistsView: View {
    var body: some View {
        List(Playlist.samples) { playlist in
            NavigationLink {
                TracksView(playlist: playlist)
            } label: {
                HStack(spacing: 10) {
                    SymbolTile(symbolName: playlist.symbolName, tint: playlist.tint.color, side: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlist.name)
                            .font(.headline)
                            .lineLimit(2)
                        Text("\(playlist.trackCount) tracks · \(playlist.durationInMinutes) min")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Playlists")
    }
}

/// One playlist's tracks; each opens the now-playing screen.
struct TracksView: View {
    let playlist: Playlist

    var body: some View {
        List {
            Section {
                ForEach(MusicTrack.queue) { track in
                    NavigationLink {
                        NowPlayingView(track: track)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .lineLimit(1)
                            Text("\(track.artist) · \(DemoDurationFormatter.minuteSecond(track.duration))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            } header: {
                Text(playlist.subtitle)
            }
        }
        .navigationTitle(playlist.name)
    }
}
