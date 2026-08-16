import Foundation

struct SocialHero: Hashable {
    let eyebrow: String
    let headline: String
    let symbolName: String
    let gradient: [DemoTint]
}

struct SocialPost: Identifiable, Hashable {
    let id = UUID()
    let author: String
    let handle: String
    let tint: DemoTint
    let timeAgo: String
    let body: String
    let hero: SocialHero?
    var likeCount: Int
    let commentCount: Int
    let shareCount: Int
    var isLiked: Bool
    let tags: [String]
    var isVerified: Bool = false

    var initials: String {
        String(author.prefix(2)).uppercased()
    }

    static let samples: [SocialPost] = [
        SocialPost(
            author: "Naomi Park",
            handle: "@naomi",
            tint: .pink,
            timeAgo: "12m",
            body: "Shipped the new onboarding flow today. Big thanks to the team for staying late on the polish pass.",
            hero: SocialHero(eyebrow: "Release", headline: "Onboarding 2.0 is live", symbolName: "sparkles", gradient: [.pink, .orange]),
            likeCount: 1284,
            commentCount: 92,
            shareCount: 14,
            isLiked: true,
            tags: ["product", "ship-it"],
            isVerified: true
        ),
        SocialPost(
            author: "Ravi Mehta",
            handle: "@ravi.codes",
            tint: .blue,
            timeAgo: "1h",
            body: "Refactored a 600-line view controller into four small ones. Compile times dropped 40%.",
            hero: nil,
            likeCount: 412,
            commentCount: 38,
            shareCount: 7,
            isLiked: false,
            tags: ["uikit", "refactor"]
        ),
        SocialPost(
            author: "Atlas Studio",
            handle: "@atlas",
            tint: .purple,
            timeAgo: "3h",
            body: "Sneak peek of the album art for our next release. Vinyl preorders open Friday.",
            hero: SocialHero(eyebrow: "Coming Soon", headline: "Cathedral Light · vinyl edition", symbolName: "music.note", gradient: [.indigo, .purple, .black]),
            likeCount: 5612,
            commentCount: 218,
            shareCount: 184,
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
            hero: SocialHero(eyebrow: "Studio", headline: "Mural draft 04", symbolName: "paintpalette.fill", gradient: [.green, .mint, .teal]),
            likeCount: 198,
            commentCount: 22,
            shareCount: 1,
            isLiked: true,
            tags: ["art"]
        ),
    ]
}

struct SocialStory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let initials: String
    let tint: DemoTint
    let isUnseen: Bool

    static let samples: [SocialStory] = [
        SocialStory(name: "Naomi", initials: "NP", tint: .pink, isUnseen: true),
        SocialStory(name: "Ravi", initials: "RM", tint: .blue, isUnseen: true),
        SocialStory(name: "Atlas", initials: "AT", tint: .purple, isUnseen: true),
        SocialStory(name: "June", initials: "JN", tint: .green, isUnseen: false),
        SocialStory(name: "Sora", initials: "SO", tint: .orange, isUnseen: true),
        SocialStory(name: "Kael", initials: "KE", tint: .indigo, isUnseen: false),
    ]
}

enum SocialCountFormatter {
    static func abbreviated(_ count: Int) -> String {
        guard count >= 1000 else { return "\(count)" }
        return String(format: "%.1fK", Double(count) / 1000)
    }
}
