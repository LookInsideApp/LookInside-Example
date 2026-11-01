import WatchKit

/// The social feed, one table row per post.
final class FeedInterfaceController: WKInterfaceController {
    @IBOutlet private var postTable: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setTitle("Feed")
        postTable.setNumberOfRows(SocialPost.samples.count, withRowType: "PostRow")
        for (index, post) in SocialPost.samples.enumerated() {
            guard let row = postTable.rowController(at: index) as? PostRowController else { continue }
            row.avatarGroup.setBackgroundColor(post.tint.uiColor)
            row.initialsLabel.setText(post.initials)
            row.authorLabel.setText(post.author)
            row.bodyLabel.setText(post.body)
        }
    }
}

final class PostRowController: NSObject {
    @IBOutlet var avatarGroup: WKInterfaceGroup!
    @IBOutlet var initialsLabel: WKInterfaceLabel!
    @IBOutlet var authorLabel: WKInterfaceLabel!
    @IBOutlet var bodyLabel: WKInterfaceLabel!
}
