import SwiftUI

/// The social feed: a row per post, each opening the whole post.
struct FeedView: View {
    @State private var posts = SocialPost.samples

    var body: some View {
        List($posts) { $post in
            NavigationLink {
                PostView(post: $post)
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    AvatarBadge(initials: post.initials, tint: post.tint, side: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(post.author)
                                .font(.headline)
                                .lineLimit(1)
                            if post.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.blue)
                                    .imageScale(.small)
                            }
                        }
                        Text(post.body)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle("Feed")
    }
}

/// One post in full, with its hero card, tags and a like button.
struct PostView: View {
    @Binding var post: SocialPost

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    AvatarBadge(initials: post.initials, tint: post.tint, side: 36)
                    VStack(alignment: .leading) {
                        Text(post.author)
                            .font(.headline)
                        Text("\(post.handle) · \(post.timeAgo)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if let hero = post.hero {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: hero.symbolName)
                            .font(.title3)
                        Text(hero.eyebrow.uppercased())
                            .font(.caption2.weight(.semibold))
                        Text(hero.headline)
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: hero.gradient.map(\.color), startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                Text(post.body)
                Text(post.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.footnote)
                    .foregroundStyle(.tint)
                Button {
                    post.isLiked.toggle()
                    post.likeCount += post.isLiked ? 1 : -1
                } label: {
                    Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                }
                .tint(.pink)
            }
        }
        .navigationTitle(post.author)
    }
}
