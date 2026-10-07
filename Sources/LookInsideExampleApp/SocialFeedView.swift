import SwiftUI

struct SocialFeedView: View {
    @State private var posts: [SocialPost] = SocialPost.samples
    @State private var stories: [SocialStory] = SocialStory.samples
    @State private var newPost = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: []) {
                    storiesStrip
                        .padding(.top, 8)

                    composer

                    ForEach($posts) { $post in
                        PostCard(post: $post)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .demoContentWidth(640)
            }
            .background(DemoTheme.groupedBackground)
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Latest", systemImage: "clock") {}
                        Button("Following", systemImage: "person.2") {}
                        Button("Trending", systemImage: "flame") {}
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var storiesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                AddStoryBubble()
                ForEach(stories) { story in
                    StoryBubble(story: story)
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarBadge(initials: "Y", tint: .blue, size: 38)
            VStack(alignment: .leading, spacing: 10) {
                TextField("Share something with your friends...", text: $newPost, axis: .vertical)
                    .lineLimit(1 ... 4)
                    .focused($composerFocused)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DemoTheme.groupedBackground)
                    )

                if composerFocused || !newPost.isEmpty {
                    HStack(spacing: 14) {
                        composerActionButton(symbol: "photo", tint: .green)
                        composerActionButton(symbol: "video", tint: .pink)
                        composerActionButton(symbol: "location", tint: .blue)
                        composerActionButton(symbol: "face.smiling", tint: .orange)
                        Spacer()
                        Button {
                            publish()
                        } label: {
                            Text("Post")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Color.accentColor, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(newPost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(newPost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    }
                }
            }
        }
        .padding(14)
        .demoCardBackground()
    }

    private func composerActionButton(symbol: String, tint: Color) -> some View {
        Button {} label: {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.body)
        }
        .buttonStyle(.plain)
    }

    private func publish() {
        let trimmed = newPost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let new = SocialPost(
            author: "You",
            handle: "@you",
            tint: .blue,
            timeAgo: "now",
            body: trimmed,
            hero: nil,
            likes: 0,
            comments: 0,
            shares: 0,
            isLiked: false,
            tags: []
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            posts.insert(new, at: 0)
            newPost = ""
            composerFocused = false
        }
    }
}

private struct PostCard: View {
    @Binding var post: SocialPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(post.body)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if !post.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tint)
                    }
                }
            }

            if let hero = post.hero {
                heroBlock(hero)
            }

            Divider()
            actions
        }
        .padding(16)
        .demoCardBackground()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            AvatarBadge(initials: post.initials, tint: post.tint, size: 44)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(post.author)
                        .font(.subheadline.weight(.semibold))
                    if post.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                HStack(spacing: 4) {
                    Text(post.handle)
                    Text("·")
                    Text(post.timeAgo)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func heroBlock(_ hero: SocialHero) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: hero.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)

            VStack(alignment: .leading, spacing: 4) {
                Text(hero.eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(hero.headline)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            .padding(16)

            Image(systemName: hero.symbol)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.55))
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actions: some View {
        HStack(spacing: 0) {
            actionButton(symbol: post.isLiked ? "heart.fill" : "heart", count: post.likes, tint: post.isLiked ? .pink : .secondary) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    post.isLiked.toggle()
                    post.likes += post.isLiked ? 1 : -1
                }
            }
            actionButton(symbol: "bubble.left", count: post.comments, tint: .secondary) {}
            actionButton(symbol: "arrowshape.turn.up.right", count: post.shares, tint: .secondary) {}
            Spacer()
            Button {} label: {
                Image(systemName: "bookmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButton(symbol: String, count: Int, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(format(count))
                    .font(.footnote.monospacedDigit())
            }
            .foregroundStyle(tint)
            .padding(.trailing, 14)
        }
        .buttonStyle(.plain)
    }

    private func format(_ count: Int) -> String {
        if count >= 1000 {
            let k = Double(count) / 1000
            return String(format: "%.1fK", k)
        }
        return "\(count)"
    }
}

private struct AddStoryBubble: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(DemoTheme.secondaryGroupedBackground)
                    .frame(width: 64, height: 64)
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            .overlay(Circle().stroke(.tint.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [3, 3])))
            Text("Your story")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StoryBubble: View {
    let story: SocialStory

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if story.isUnseen {
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.pink, .orange, .yellow, .pink],
                                center: .center
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 70, height: 70)
                }
                AvatarBadge(initials: story.initials, tint: story.tint, size: story.isUnseen ? 60 : 64)
            }
            Text(story.name)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: 64)
        }
    }
}

struct SocialPost: Identifiable {
    let id = UUID()
    let author: String
    let handle: String
    let tint: Color
    let timeAgo: String
    let body: String
    let hero: SocialHero?
    var likes: Int
    let comments: Int
    let shares: Int
    var isLiked: Bool
    let tags: [String]
    var isVerified: Bool = false

    /// "Naomi Park" becomes "NP"; a single name keeps its first two letters.
    var initials: String {
        let words = author.split(separator: " ")
        guard words.count > 1 else { return String(author.prefix(2)).uppercased() }
        return words.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    static let samples: [SocialPost] = [
        SocialPost(
            author: "Naomi Park",
            handle: "@naomi",
            tint: .pink,
            timeAgo: "12m",
            body: "Shipped the new onboarding flow today. Big thanks to the team for staying late on the polish pass.",
            hero: SocialHero(eyebrow: "Release", headline: "Onboarding 2.0 is live", symbol: "sparkles", gradient: [.pink, .orange]),
            likes: 1284,
            comments: 92,
            shares: 14,
            isLiked: true,
            tags: ["product", "ship-it"],
            isVerified: true
        ),
        SocialPost(
            author: "Ravi Mehta",
            handle: "@ravi.codes",
            tint: .blue,
            timeAgo: "1h",
            body: "Refactored a 600-line view controller into 4 small SwiftUI views. Compile times dropped 40%.",
            hero: nil,
            likes: 412,
            comments: 38,
            shares: 7,
            isLiked: false,
            tags: ["swiftui", "refactor"]
        ),
        SocialPost(
            author: "Atlas Studio",
            handle: "@atlas",
            tint: .purple,
            timeAgo: "3h",
            body: "Sneak peek of the album art for our next release. Vinyl preorders open Friday.",
            hero: SocialHero(eyebrow: "Coming Soon", headline: "Cathedral Light · vinyl edition", symbol: "music.note", gradient: [.indigo, .purple, .black]),
            likes: 5612,
            comments: 218,
            shares: 184,
            isLiked: false,
            tags: ["music", "vinyl"],
            isVerified: true
        ),
        SocialPost(
            author: "June",
            handle: "@junesketches",
            tint: .green,
            timeAgo: "5h",
            body: "Trying out a new color palette for the kitchen mural. Picking between sage and sea-glass.",
            hero: SocialHero(eyebrow: "Studio", headline: "Mural draft 04", symbol: "paintpalette.fill", gradient: [.green, .mint, .teal]),
            likes: 198,
            comments: 22,
            shares: 1,
            isLiked: true,
            tags: ["art"]
        ),
    ]
}

struct SocialHero {
    let eyebrow: String
    let headline: String
    let symbol: String
    let gradient: [Color]
}

struct SocialStory: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let tint: Color
    let isUnseen: Bool

    static let samples: [SocialStory] = [
        .init(name: "Naomi", initials: "NP", tint: .pink, isUnseen: true),
        .init(name: "Ravi", initials: "RM", tint: .blue, isUnseen: true),
        .init(name: "Atlas", initials: "AT", tint: .purple, isUnseen: true),
        .init(name: "June", initials: "JN", tint: .green, isUnseen: false),
        .init(name: "Sora", initials: "SO", tint: .orange, isUnseen: true),
        .init(name: "Kael", initials: "KE", tint: .indigo, isUnseen: false),
    ]
}
