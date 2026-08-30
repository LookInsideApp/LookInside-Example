import SwiftUI

struct ChatView: View {
    @State private var conversations: [Conversation] = Conversation.samples
    @State private var selectedID: Conversation.ID?
    @State private var query = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let selected = binding(for: selectedID) {
                ConversationDetail(conversation: selected)
            } else {
                placeholder
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List(selection: $selectedID) {
            Section {
                ForEach(filteredConversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .tag(conversation.id)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                conversations.removeAll { $0.id == conversation.id }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                                    conversations[index].isPinned.toggle()
                                }
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, placement: .automatic, prompt: "Search messages")
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {} label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }

    private var filteredConversations: [Conversation] {
        let pinned = conversations.filter(\.isPinned)
        let regular = conversations.filter { !$0.isPinned }
        let combined = pinned + regular
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return combined
        }
        let lower = query.lowercased()
        return combined.filter {
            $0.name.lowercased().contains(lower) ||
                $0.lastMessage.lowercased().contains(lower)
        }
    }

    private func binding(for id: Conversation.ID?) -> Binding<Conversation>? {
        guard let id, let index = conversations.firstIndex(where: { $0.id == id }) else { return nil }
        return $conversations[index]
    }

    private var placeholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Pick a conversation")
                .font(.title3.weight(.medium))
            Text("Or start a new one with the compose button.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DemoTheme.groupedBackground)
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarBadge(initials: conversation.initials, tint: conversation.tint, size: 48)
                .overlay(alignment: .bottomTrailing) {
                    if conversation.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(DemoTheme.secondaryGroupedBackground, lineWidth: 2))
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(conversation.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.timestamp)
                        .font(.caption)
                        .foregroundStyle(conversation.unreadCount > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                }
                HStack(alignment: .top, spacing: 6) {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor, in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct ConversationDetail: View {
    @Binding var conversation: Conversation
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { index, message in
                            messageBubble(
                                message: message,
                                showAvatar: shouldShowAvatar(at: index),
                                showTimestamp: shouldShowTimestamp(at: index)
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .demoContentWidth(DemoTheme.chatContentMaxWidth)
                }
                .background(DemoTheme.groupedBackground)
                .demoOnChange(of: conversation.messages.count) {
                    if let last = conversation.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()
            inputBar
        }
        .navigationTitle(conversation.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button {} label: { Image(systemName: "video") }
                    Button {} label: { Image(systemName: "phone") }
                    Button {} label: { Image(systemName: "info.circle") }
                }
            }
        }
        .onAppear {
            conversation.unreadCount = 0
        }
    }

    private func shouldShowAvatar(at index: Int) -> Bool {
        let message = conversation.messages[index]
        guard !message.isFromMe else { return false }
        let next = conversation.messages[safe: index + 1]
        return next == nil || next!.isFromMe
    }

    private func shouldShowTimestamp(at index: Int) -> Bool {
        guard index < conversation.messages.count else { return false }
        let current = conversation.messages[index]
        let prev = conversation.messages[safe: index - 1]
        return prev == nil || prev!.timestamp.timeIntervalSince(current.timestamp).magnitude > 60 * 30
    }

    private func messageBubble(message: ChatMessage, showAvatar: Bool, showTimestamp: Bool) -> some View {
        VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
            if showTimestamp {
                Text(message.timeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }

            HStack(alignment: .bottom, spacing: 8) {
                if !message.isFromMe {
                    if showAvatar {
                        AvatarBadge(initials: conversation.initials, tint: conversation.tint, size: 28)
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }

                if message.isFromMe {
                    Spacer(minLength: 40)
                }

                bubbleContent(message: message)

                if !message.isFromMe {
                    Spacer(minLength: 40)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isFromMe ? .trailing : .leading)
    }

    @ViewBuilder
    private func bubbleContent(message: ChatMessage) -> some View {
        switch message.kind {
        case let .text(body):
            Text(body)
                .font(.body)
                .foregroundStyle(message.isFromMe ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isFromMe
                        ? AnyShapeStyle(Color.accentColor.gradient)
                        : AnyShapeStyle(DemoTheme.secondaryGroupedBackground),
                    in: RoundedRectangle(cornerRadius: DemoTheme.bubbleCorner, style: .continuous)
                )
        case let .image(symbol, tint):
            ZStack {
                LinearGradient(colors: [tint.opacity(0.85), tint.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white)
            }
            .frame(width: 160, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: DemoTheme.bubbleCorner, style: .continuous))
        case let .audio(duration):
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                waveform
                Text(formatDuration(duration))
                    .font(.caption.monospacedDigit())
            }
            .foregroundStyle(message.isFromMe ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                message.isFromMe
                    ? AnyShapeStyle(Color.accentColor.gradient)
                    : AnyShapeStyle(DemoTheme.secondaryGroupedBackground),
                in: RoundedRectangle(cornerRadius: DemoTheme.bubbleCorner, style: .continuous)
            )
        }
    }

    private var waveform: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 18) { idx in
                Capsule()
                    .frame(width: 2, height: barHeight(idx))
            }
        }
    }

    private func barHeight(_ index: Int) -> CGFloat {
        let pattern: [CGFloat] = [6, 10, 18, 12, 22, 16, 8, 14, 20, 10, 6, 18, 24, 12, 8, 16, 12, 8]
        return pattern[index % pattern.count]
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button {} label: {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $draft, axis: .vertical)
                    .lineLimit(1 ... 5)
                    .focused($inputFocused)
                Button {} label: {
                    Image(systemName: "face.smiling")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(DemoTheme.secondaryGroupedBackground)
            )

            Button {
                send()
            } label: {
                Image(systemName: draft.trimmingCharacters(in: .whitespaces).isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .demoContentWidth(DemoTheme.chatContentMaxWidth)
        .background(.bar)
    }

    private func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let new = ChatMessage(kind: .text(trimmed), isFromMe: true, timestamp: Date())
        conversation.messages.append(new)
        draft = ""
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct Conversation: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let tint: Color
    var lastMessage: String {
        messages.last.map(messageSummary) ?? ""
    }

    let timestamp: String
    var unreadCount: Int
    let isOnline: Bool
    var isPinned: Bool
    var messages: [ChatMessage]

    private func messageSummary(_ message: ChatMessage) -> String {
        switch message.kind {
        case let .text(body): body
        case .image: "📷 Photo"
        case .audio: "🎙 Voice message"
        }
    }

    static let samples: [Conversation] = {
        let now = Date()
        func minutes(_ delta: Int) -> Date {
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
                    ChatMessage(kind: .text("Did you see the onboarding numbers from yesterday?"), isFromMe: false, timestamp: minutes(180)),
                    ChatMessage(kind: .text("Yeah, completion is up 18%"), isFromMe: true, timestamp: minutes(178)),
                    ChatMessage(kind: .text("That's huge. We should ship the polish pass next."), isFromMe: false, timestamp: minutes(174)),
                    ChatMessage(kind: .image(symbol: "chart.line.uptrend.xyaxis", tint: .pink), isFromMe: false, timestamp: minutes(172)),
                    ChatMessage(kind: .text("Pulled the cohort breakdown ☝️"), isFromMe: false, timestamp: minutes(172)),
                    ChatMessage(kind: .text("Love it. Let's review at standup tomorrow."), isFromMe: true, timestamp: minutes(20)),
                    ChatMessage(kind: .text("Sounds good, see you then ✨"), isFromMe: false, timestamp: minutes(2)),
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
                    ChatMessage(kind: .text("Heads up: 0.2.0 server release is queued."), isFromMe: false, timestamp: minutes(240)),
                    ChatMessage(kind: .text("Tagging now."), isFromMe: true, timestamp: minutes(235)),
                    ChatMessage(kind: .audio(duration: 38), isFromMe: false, timestamp: minutes(230)),
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
                    ChatMessage(kind: .text("Don't forget Sunday lunch 🍝"), isFromMe: false, timestamp: minutes(1500)),
                    ChatMessage(kind: .text("Wouldn't miss it ❤️"), isFromMe: true, timestamp: minutes(1490)),
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
                    ChatMessage(kind: .text("Pulled three new mood references for the cover art."), isFromMe: false, timestamp: minutes(3200)),
                    ChatMessage(kind: .image(symbol: "moon.stars", tint: .purple), isFromMe: false, timestamp: minutes(3190)),
                    ChatMessage(kind: .image(symbol: "sparkles", tint: .indigo), isFromMe: false, timestamp: minutes(3180)),
                    ChatMessage(kind: .text("Thoughts? 🎨"), isFromMe: false, timestamp: minutes(3175)),
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
                    ChatMessage(kind: .text("Mural is almost done, send pics tomorrow!"), isFromMe: false, timestamp: minutes(5800)),
                    ChatMessage(kind: .text("Yes please 🌿"), isFromMe: true, timestamp: minutes(5790)),
                ]
            ),
        ]
    }()
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let kind: Kind
    let isFromMe: Bool
    let timestamp: Date

    enum Kind {
        case text(String)
        case image(symbol: String, tint: Color)
        case audio(duration: TimeInterval)
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}
