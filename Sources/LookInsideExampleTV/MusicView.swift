import SwiftUI

/// A now-playing screen: animated artwork beside the track details and the
/// transport controls, then two shelves of cards.
struct MusicView: View {
    @State private var currentIndex = 0
    @State private var isPlaying = true
    @State private var playbackFraction = 0.32
    @State private var isShuffled = false
    @State private var repeatMode: RepeatMode = .off

    private var currentTrack: MusicTrack {
        MusicTrack.queue[currentIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DemoMetrics.sectionSpacing) {
                nowPlaying

                Shelf(title: "Up Next") {
                    ForEach(Array(MusicTrack.queue.enumerated()), id: \.element.id) { index, track in
                        Button {
                            play(index)
                        } label: {
                            TrackCard(track: track, isCurrent: index == currentIndex, isPlaying: isPlaying)
                        }
                        .buttonStyle(.card)
                    }
                }

                Shelf(title: "Made for You") {
                    ForEach(Playlist.samples) { playlist in
                        Button {} label: {
                            PlaylistCard(playlist: playlist)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
            .padding(.vertical, 24)
        }
    }

    private var nowPlaying: some View {
        HStack(alignment: .center, spacing: 72) {
            AlbumArtwork(track: currentTrack, isPlaying: isPlaying)
                .frame(width: 400, height: 400)

            VStack(alignment: .leading, spacing: 16) {
                Text(currentTrack.album.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(.secondary)
                Text(currentTrack.title)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                Text(currentTrack.artist)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                progress
                    .padding(.top, 16)

                transportControls
                    .padding(.top, 16)
            }
            .focusSection()
        }
    }

    private var progress: some View {
        VStack(spacing: 12) {
            ProgressView(value: playbackFraction)
                .tint(currentTrack.tint.color)
            HStack {
                Text(DemoDurationFormatter.minuteSecond(currentTrack.duration * playbackFraction))
                Spacer()
                Text("-" + DemoDurationFormatter.minuteSecond(currentTrack.duration * (1 - playbackFraction)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 760)
    }

    private var transportControls: some View {
        HStack(spacing: 28) {
            Button {
                isShuffled.toggle()
            } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(isShuffled ? currentTrack.tint.color : Color.primary)
            }

            Button {
                play(max(0, currentIndex - 1))
            } label: {
                Image(systemName: "backward.fill")
            }

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 48)
            }

            Button {
                play(min(MusicTrack.queue.count - 1, currentIndex + 1))
            } label: {
                Image(systemName: "forward.fill")
            }

            Button {
                repeatMode = repeatMode.next
            } label: {
                Image(systemName: repeatMode.symbolName)
                    .foregroundStyle(repeatMode == .off ? Color.primary : currentTrack.tint.color)
            }
        }
    }

    private func play(_ index: Int) {
        guard index != currentIndex else { return }
        currentIndex = index
        playbackFraction = 0
        isPlaying = true
    }
}

/// The large artwork: a gradient, three concentric rings and a slowly
/// pulsing symbol.
private struct AlbumArtwork: View {
    let track: MusicTrack
    let isPlaying: Bool
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [track.tint.color.opacity(0.95), track.tint.color.opacity(0.55), .black.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 2)
                }

            ForEach(0 ..< 3) { ringIndex in
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 2)
                    .frame(width: CGFloat(200 + ringIndex * 90))
            }

            VStack(spacing: 20) {
                Image(systemName: track.symbolName)
                    .font(.system(size: 110, weight: .light))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
                    .scaleEffect(isPulsing && isPlaying ? 1.04 : 0.98)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isPulsing)

                Text(track.album.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .shadow(color: track.tint.color.opacity(0.45), radius: 32, y: 20)
        .onAppear { isPulsing = true }
    }
}

private struct TrackCard: View {
    let track: MusicTrack
    let isCurrent: Bool
    let isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [track.tint.color, track.tint.color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: track.symbolName)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isCurrent {
                    Label("Now Playing", systemImage: "waveform")
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isPlaying)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.35), in: Capsule())
                        .padding(16)
                }
            }
            .frame(width: 400, height: 225)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text("\(track.artist) · \(DemoDurationFormatter.minuteSecond(track.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(20)
            .frame(width: 400, alignment: .leading)
        }
    }
}

private struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(playlist.tint.color.gradient)
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: playlist.symbolName)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(playlist.subtitle)
                        .font(.caption2.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(24)
            }
            .frame(width: 300, height: 300)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text("\(playlist.trackCount) tracks · \(playlist.durationInMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(20)
            .frame(width: 300, alignment: .leading)
        }
    }
}
