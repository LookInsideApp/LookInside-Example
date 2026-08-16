import Foundation

/// The single mutable source of truth shared by the conversation list and the
/// conversation detail. Deliberately a plain class with a change callback
/// rather than any observation framework, so both view controllers stay pure
/// UIKit.
final class ChatStore {
    private(set) var conversations: [Conversation] = Conversation.samples

    var onChange: (() -> Void)?

    func conversation(with identifier: Conversation.ID) -> Conversation? {
        conversations.first { $0.id == identifier }
    }

    /// Pinned conversations first, then an optional case-insensitive filter on
    /// name and last message.
    func sortedConversations(matching query: String) -> [Conversation] {
        let ordered = conversations.filter(\.isPinned) + conversations.filter { !$0.isPinned }
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedQuery.isEmpty else { return ordered }
        return ordered.filter {
            $0.name.lowercased().contains(trimmedQuery) || $0.lastMessage.lowercased().contains(trimmedQuery)
        }
    }

    func remove(_ identifier: Conversation.ID) {
        conversations.removeAll { $0.id == identifier }
        onChange?()
    }

    func togglePinned(_ identifier: Conversation.ID) {
        guard let index = conversations.firstIndex(where: { $0.id == identifier }) else { return }
        conversations[index].isPinned.toggle()
        onChange?()
    }

    func markAsRead(_ identifier: Conversation.ID) {
        guard let index = conversations.firstIndex(where: { $0.id == identifier }),
              conversations[index].unreadCount != 0
        else { return }
        conversations[index].unreadCount = 0
        onChange?()
    }

    func append(_ message: ChatMessage, to identifier: Conversation.ID) {
        guard let index = conversations.firstIndex(where: { $0.id == identifier }) else { return }
        conversations[index].messages.append(message)
        onChange?()
    }
}
