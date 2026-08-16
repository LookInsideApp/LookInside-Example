import Foundation

struct ChatMessage: Identifiable, Hashable {
    enum Kind: Hashable {
        case text(String)
        case image(symbolName: String, tint: DemoTint)
        case audio(duration: TimeInterval)
    }

    let id = UUID()
    let kind: Kind
    let isFromMe: Bool
    let timestamp: Date

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

struct Conversation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let initials: String
    let tint: DemoTint
    let timestamp: String
    var unreadCount: Int
    let isOnline: Bool
    var isPinned: Bool
    var messages: [ChatMessage]

    var lastMessage: String {
        guard let latest = messages.last else { return "" }
        switch latest.kind {
        case let .text(body): return body
        case .image: return "📷 Photo"
        case .audio: return "🎙 Voice message"
        }
    }

    static let samples: [Conversation] = {
        let now = Date()
        func minutesAgo(_ delta: Int) -> Date {
            now.addingTimeInterval(TimeInterval(-delta * 60))
        }

        return [
            Conversation(
                name: "Naomi Park",
                initials: "NP",
                tint: .pink,
                timestamp: "12:42",
                unreadCount: 2,
                isOnline: true,
                isPinned: true,
                messages: [
                    ChatMessage(kind: .text("Did you see the onboarding numbers from yesterday?"), isFromMe: false, timestamp: minutesAgo(180)),
                    ChatMessage(kind: .text("Yeah, completion is up 18%"), isFromMe: true, timestamp: minutesAgo(178)),
                    ChatMessage(kind: .text("That's huge. We should ship the polish pass next."), isFromMe: false, timestamp: minutesAgo(174)),
                    ChatMessage(kind: .image(symbolName: "chart.line.uptrend.xyaxis", tint: .pink), isFromMe: false, timestamp: minutesAgo(172)),
                    ChatMessage(kind: .text("Pulled the cohort breakdown ☝️"), isFromMe: false, timestamp: minutesAgo(172)),
                    ChatMessage(kind: .text("Love it. Let's review at standup tomorrow."), isFromMe: true, timestamp: minutesAgo(20)),
                    ChatMessage(kind: .text("Sounds good, see you then ✨"), isFromMe: false, timestamp: minutesAgo(2)),
                ]
            ),
            Conversation(
                name: "Engineering",
                initials: "EN",
                tint: .blue,
                timestamp: "11:08",
                unreadCount: 0,
                isOnline: false,
                isPinned: true,
                messages: [
                    ChatMessage(kind: .text("Heads up: the 0.2.0 server release is queued."), isFromMe: false, timestamp: minutesAgo(240)),
                    ChatMessage(kind: .text("Tagging now."), isFromMe: true, timestamp: minutesAgo(235)),
                    ChatMessage(kind: .audio(duration: 38), isFromMe: false, timestamp: minutesAgo(230)),
                ]
            ),
            Conversation(
                name: "Mom",
                initials: "M",
                tint: .orange,
                timestamp: "Yesterday",
                unreadCount: 0,
                isOnline: false,
                isPinned: false,
                messages: [
                    ChatMessage(kind: .text("Don't forget Sunday lunch 🍝"), isFromMe: false, timestamp: minutesAgo(1500)),
                    ChatMessage(kind: .text("Wouldn't miss it ❤️"), isFromMe: true, timestamp: minutesAgo(1490)),
                ]
            ),
            Conversation(
                name: "Atlas Studio",
                initials: "AS",
                tint: .purple,
                timestamp: "Mon",
                unreadCount: 4,
                isOnline: true,
                isPinned: false,
                messages: [
                    ChatMessage(kind: .text("Pulled three new mood references for the cover art."), isFromMe: false, timestamp: minutesAgo(3200)),
                    ChatMessage(kind: .image(symbolName: "moon.stars", tint: .purple), isFromMe: false, timestamp: minutesAgo(3190)),
                    ChatMessage(kind: .image(symbolName: "sparkles", tint: .indigo), isFromMe: false, timestamp: minutesAgo(3180)),
                    ChatMessage(kind: .text("Thoughts? 🎨"), isFromMe: false, timestamp: minutesAgo(3175)),
                ]
            ),
            Conversation(
                name: "June",
                initials: "JN",
                tint: .green,
                timestamp: "Sat",
                unreadCount: 0,
                isOnline: false,
                isPinned: false,
                messages: [
                    ChatMessage(kind: .text("Mural is almost done, send pics tomorrow!"), isFromMe: false, timestamp: minutesAgo(5800)),
                    ChatMessage(kind: .text("Yes please 🌿"), isFromMe: true, timestamp: minutesAgo(5790)),
                ]
            ),
        ]
    }()
}
