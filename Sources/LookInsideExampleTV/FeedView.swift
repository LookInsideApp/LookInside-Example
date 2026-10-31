import SwiftUI

/// A social feed laid out for the living room: a shelf of stories above a
/// shelf of post cards. Pressing a post likes it.
struct FeedView: View {
    @State private var posts = SocialPost.samples
    private let stories = SocialStory.samples

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DemoMetrics.sectionSpacing) {
                Shelf(title: "Stories") {
                    ForEach(stories) { story in
                        Button {} label: {
                            StoryCard(story: story)
                        }
                        .buttonStyle(.card)
                    }
                }

                Shelf(title: "Latest Posts") {
                    ForEach($posts) { $post in
                        Button {
                            post.isLiked.toggle()
                            post.likeCount += post.isLiked ? 1 : -1
                        } label: {
                            PostCard(post: post)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
            .padding(.vertical, 24)
        }
    }
}

private struct StoryCard: View {
    let story: SocialStory

    var body: some View {
        VStack(spacing: 18) {
            AvatarBadge(initials: story.initials, tint: story.tint.color, size: 120)
                .padding(8)
                .overlay {
                    if story.isUnseen {
                        Circle()
                            .stroke(
                                AngularGradient(colors: [.pink, .orange, .yellow, .purple, .pink], center: .center),
                                lineWidth: 6
                            )
                    }
                }
            Text(story.name)
                .font(.callout.weight(.medium))
                .lineLimit(1)
        }
        .padding(24)
        .frame(width: 220)
    }
}

private struct PostCard: View {
    let post: SocialPost

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            Text(post.body)
                .font(.callout)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if !post.tags.isEmpty {
                HStack(spacing: 12) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(post.tint.color)
                    }
                }
            }

            if let hero = post.hero {
                HeroBanner(hero: hero)
            }

            Spacer(minLength: 0)

            actions
        }
        .padding(28)
        .frame(width: 640, height: 520, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 18) {
            AvatarBadge(initials: post.initials, tint: post.tint.color, size: 72)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(post.author)
                        .font(.callout.weight(.semibold))
                    if post.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                Text("\(post.handle) · \(post.timeAgo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 36) {
            Label(SocialCountFormatter.abbreviated(post.likeCount), systemImage: post.isLiked ? "heart.fill" : "heart")
                .foregroundStyle(post.isLiked ? Color.pink : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
            Label(SocialCountFormatter.abbreviated(post.commentCount), systemImage: "bubble.left")
                .foregroundStyle(.secondary)
            Label(SocialCountFormatter.abbreviated(post.shareCount), systemImage: "arrowshape.turn.up.right")
                .foregroundStyle(.secondary)
        }
        .font(.caption.weight(.medium))
    }
}

/// The gradient strip some posts carry, with an eyebrow and a headline.
private struct HeroBanner: View {
    let hero: SocialHero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: hero.gradient.map(\.color),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: hero.symbolName)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(hero.eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.8))
                Text(hero.headline)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(20)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
