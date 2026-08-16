import Foundation

struct MusicTrack: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let symbolName: String
    let tint: DemoTint

    static let queue: [MusicTrack] = [
        MusicTrack(title: "Midnight Resonance", artist: "Ayla Wren", album: "Cathedral Light", duration: 232, symbolName: "moon.stars.fill", tint: .indigo),
        MusicTrack(title: "Soft Drift", artist: "Halo Bay", album: "Boreal", duration: 198, symbolName: "wave.3.right", tint: .teal),
        MusicTrack(title: "Eastbound", artist: "Kite & Kin", album: "Routes", duration: 274, symbolName: "sun.haze.fill", tint: .orange),
        MusicTrack(title: "Pavement Glow", artist: "Marlon Vega", album: "Streets", duration: 216, symbolName: "car.fill", tint: .pink),
        MusicTrack(title: "Quiet Static", artist: "Northern Loom", album: "Threshold", duration: 305, symbolName: "antenna.radiowaves.left.and.right", tint: .purple),
        MusicTrack(title: "Open Air", artist: "The Atrium", album: "Pavilion", duration: 248, symbolName: "wind", tint: .mint),
    ]
}

struct Playlist: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let symbolName: String
    let tint: DemoTint
    let trackCount: Int
    let durationInMinutes: Int

    static let samples: [Playlist] = [
        Playlist(name: "Late Night Coding", subtitle: "FOCUS", symbolName: "laptopcomputer", tint: .indigo, trackCount: 24, durationInMinutes: 92),
        Playlist(name: "Sunrise Run", subtitle: "ENERGY", symbolName: "sun.max.fill", tint: .orange, trackCount: 18, durationInMinutes: 68),
        Playlist(name: "Rainy Sunday", subtitle: "MELLOW", symbolName: "cloud.rain.fill", tint: .blue, trackCount: 31, durationInMinutes: 124),
        Playlist(name: "Pop & Polish", subtitle: "DAILY MIX", symbolName: "sparkles", tint: .pink, trackCount: 22, durationInMinutes: 81),
    ]
}

enum RepeatMode: String, CaseIterable {
    case off
    case all
    case one

    var next: RepeatMode {
        switch self {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }

    var symbolName: String {
        switch self {
        case .off, .all: "repeat"
        case .one: "repeat.1"
        }
    }
}

enum DemoDurationFormatter {
    static func minuteSecond(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
