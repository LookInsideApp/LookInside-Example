import SwiftUI

struct MusicPlayerView: View {
    @State private var currentIndex = 0
    @State private var isPlaying = true
    @State private var progress: Double = 0.32
    @State private var volume: Double = 0.65
    @State private var isShuffle = false
    @State private var repeatMode: RepeatMode = .off
    @State private var showQueue = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    nowPlayingCard
                    progressBar
                    transportRow
                    secondaryControls
                    upNextSection
                    playlistSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .demoContentWidth(640)
            }
            .background(DemoTheme.groupedBackground)
            .navigationTitle("Listening")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showQueue = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showQueue) {
                QueueSheet(tracks: MusicTrack.queue, current: $currentIndex)
            }
        }
    }

    private var current: MusicTrack {
        MusicTrack.queue[currentIndex]
    }

    private var nowPlayingCard: some View {
        VStack(spacing: 20) {
            AlbumArtView(track: current, isPlaying: isPlaying)
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Text(current.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(current.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(current.album.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            Slider(value: $progress, in: 0 ... 1)
                .tint(current.tint)
            HStack {
                Text(formatTime(current.duration * progress))
                Spacer()
                Text("-" + formatTime(current.duration * (1 - progress)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private var transportRow: some View {
        HStack(spacing: 28) {
            Button {
                currentIndex = max(0, currentIndex - 1)
                progress = 0
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Button {
                isPlaying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(current.tint.gradient)
                        .frame(width: 72, height: 72)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
                .shadow(color: current.tint.opacity(0.45), radius: 18, y: 8)
            }
            .buttonStyle(.plain)

            Button {
                currentIndex = min(MusicTrack.queue.count - 1, currentIndex + 1)
                progress = 0
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var secondaryControls: some View {
        HStack {
            Button {
                isShuffle.toggle()
            } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(isShuffle ? current.tint : Color.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(value: $volume, in: 0 ... 1)
                    .tint(.secondary)
                    .frame(width: 140)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                repeatMode = repeatMode.next
            } label: {
                Image(systemName: repeatMode.symbol)
                    .foregroundStyle(repeatMode == .off ? Color.secondary : current.tint)
            }
            .buttonStyle(.plain)
        }
        .font(.title3)
    }

    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Up Next")
                    .font(.headline)
                Spacer()
                Button("See queue") { showQueue = true }
                    .font(.subheadline)
            }

            VStack(spacing: 0) {
                ForEach(Array(MusicTrack.queue.enumerated().dropFirst(currentIndex + 1).prefix(3)), id: \.element.id) { index, track in
                    QueueRow(track: track, index: index, isCurrent: false) {
                        currentIndex = index
                        progress = 0
                    }
                    if track.id != MusicTrack.queue.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .demoCardBackground()
        }
    }

    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Made for you")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Playlist.samples) { playlist in
                        PlaylistCard(playlist: playlist)
                    }
                }
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct AlbumArtView: View {
    let track: MusicTrack
    let isPlaying: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [track.tint.opacity(0.95), track.tint.opacity(0.55), .black.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }

            ForEach(0 ..< 3) { index in
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                    .frame(width: CGFloat(120 + index * 60))
                    .blur(radius: 0.5)
            }

            VStack(spacing: 14) {
                Image(systemName: track.symbol)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 6)
                    .scaleEffect(pulse ? 1.04 : 0.98)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

                Text(track.album.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .shadow(color: track.tint.opacity(0.45), radius: 24, y: 16)
        .onAppear { pulse = true }
    }
}

private struct QueueRow: View {
    let track: MusicTrack
    let index: Int
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(track.tint.gradient)
                    Image(systemName: track.symbol)
                        .foregroundStyle(.white)
                        .font(.callout)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(track.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isCurrent {
                    waveformIndicator
                        .foregroundStyle(track.tint)
                } else {
                    Text(formatDuration(track.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    @ViewBuilder
    private var waveformIndicator: some View {
        if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, *) {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, options: .repeating)
        } else {
            Image(systemName: "waveform")
        }
    }
}

private struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(playlist.tint.gradient)
                    .frame(width: 168, height: 168)

                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: playlist.symbol)
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.title3)
                    Text(playlist.subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(1.4)
                }
                .padding(14)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(playlist.trackCount) tracks · \(playlist.duration) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 168, alignment: .leading)
    }
}

private struct QueueSheet: View {
    let tracks: [MusicTrack]
    @Binding var current: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    Button {
                        current = index
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .frame(width: 22, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title).font(.subheadline.weight(.semibold))
                                Text(track.artist).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if index == current {
                                Image(systemName: "speaker.wave.2.fill").foregroundStyle(track.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Queue")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private enum RepeatMode: String, CaseIterable {
    case off, all, one

    var next: RepeatMode {
        switch self {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }

    var symbol: String {
        switch self {
        case .off: "repeat"
        case .all: "repeat"
        case .one: "repeat.1"
        }
    }
}

struct MusicTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let symbol: String
    let tint: Color

    static let queue: [MusicTrack] = [
        .init(title: "Midnight Resonance", artist: "Ayla Wren", album: "Cathedral Light", duration: 232, symbol: "moon.stars.fill", tint: .indigo),
        .init(title: "Soft Drift", artist: "Halo Bay", album: "Boreal", duration: 198, symbol: "wave.3.right", tint: .teal),
        .init(title: "Eastbound", artist: "Kite & Kin", album: "Routes", duration: 274, symbol: "sun.haze.fill", tint: .orange),
        .init(title: "Pavement Glow", artist: "Marlon Vega", album: "Streets", duration: 216, symbol: "car.fill", tint: .pink),
        .init(title: "Quiet Static", artist: "Northern Loom", album: "Threshold", duration: 305, symbol: "antenna.radiowaves.left.and.right", tint: .purple),
        .init(title: "Open Air", artist: "The Atrium", album: "Pavilion", duration: 248, symbol: "wind", tint: .mint),
    ]
}

struct Playlist: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let trackCount: Int
    let duration: Int

    static let samples: [Playlist] = [
        .init(name: "Late Night Coding", subtitle: "FOCUS", symbol: "laptopcomputer", tint: .indigo, trackCount: 24, duration: 92),
        .init(name: "Sunrise Run", subtitle: "ENERGY", symbol: "sun.max.fill", tint: .orange, trackCount: 18, duration: 68),
        .init(name: "Rainy Sunday", subtitle: "MELLOW", symbol: "cloud.rain.fill", tint: .blue, trackCount: 31, duration: 124),
        .init(name: "Pop & Polish", subtitle: "DAILY MIX", symbol: "sparkles", tint: .pink, trackCount: 22, duration: 81),
    ]
}
