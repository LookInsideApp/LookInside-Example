import SwiftUI

/// A now-playing screen: artwork, the track, a progress bar, the transport
/// buttons, and the volume on the Digital Crown.
struct NowPlayingView: View {
    let track: MusicTrack
    @State private var isPlaying = true
    @State private var elapsed: TimeInterval = 74
    @State private var volume = 0.6

    var body: some View {
        VStack(spacing: 8) {
            SymbolTile(symbolName: track.symbolName, tint: track.tint.color, side: 56)
            VStack(spacing: 2) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            ProgressView(value: elapsed, total: track.duration)
                .tint(track.tint.color)
            HStack {
                Text(DemoDurationFormatter.minuteSecond(elapsed))
                Spacer()
                Text("-" + DemoDurationFormatter.minuteSecond(track.duration - elapsed))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    elapsed = 0
                } label: {
                    Image(systemName: "backward.fill")
                }
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                .tint(track.tint.color)
                Button {
                    elapsed = min(track.duration, elapsed + 30)
                } label: {
                    Image(systemName: "forward.fill")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 4)
        .focusable()
        .digitalCrownRotation($volume, from: 0, through: 1, by: 0.05, sensitivity: .low)
        .navigationTitle("Now Playing")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Gauge(value: volume) {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(track.tint.color)
            }
        }
    }
}
