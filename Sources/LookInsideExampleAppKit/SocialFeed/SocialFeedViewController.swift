import AppKit

/// The feed screen: a story strip and composer above a view-based
/// `NSTableView` with automatic row heights, fed by a diffable data source.
final class SocialFeedViewController: NSViewController {
    private enum Section {
        case posts
    }

    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private var dataSource: NSTableViewDiffableDataSource<Section, SocialPost.ID>!

    private var posts = SocialPost.samples

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        let storyStripView = StoryStripView(stories: SocialStory.samples)
        let composerView = ComposerView()
        composerView.onPublish = { [weak self] body in
            self?.publishPost(body: body)
        }

        buildTableView()

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 12,
            alignment: .centerX,
            views: [storyStripView, composerView, scrollView]
        )
        containerView.addSubview(columnStackView)

        let preferredWidthConstraint = columnStackView.widthAnchor.constraint(
            equalTo: containerView.widthAnchor,
            constant: -32
        )
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            columnStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            columnStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            columnStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            columnStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth),
            preferredWidthConstraint,

            storyStripView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
            composerView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildDataSource()
        applySnapshot(animated: false)
    }

    // MARK: - Table

    private func buildTableView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("PostColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.style = .plain
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 0, height: 8)
        tableView.usesAutomaticRowHeights = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
    }

    private func buildDataSource() {
        dataSource = NSTableViewDiffableDataSource<Section, SocialPost.ID>(
            tableView: tableView
        ) { [weak self] tableView, _, _, postID in
            let existingCellView = tableView.makeView(
                withIdentifier: PostTableCellView.reuseIdentifier,
                owner: self
            ) as? PostTableCellView
            let cellView = existingCellView ?? PostTableCellView()
            cellView.identifier = PostTableCellView.reuseIdentifier

            guard let post = self?.posts.first(where: { $0.id == postID }) else { return cellView }
            cellView.configure(with: post)
            cellView.onToggleLike = { [weak self] in
                self?.toggleLike(postID: postID)
            }
            return cellView
        }
    }

    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SocialPost.ID>()
        snapshot.appendSections([.posts])
        snapshot.appendItems(posts.map(\.id), toSection: .posts)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Interaction

    private func publishPost(body: String) {
        let newPost = SocialPost(
            author: "You",
            handle: "@you",
            tint: .blue,
            timeAgo: "now",
            body: body,
            hero: nil,
            likeCount: 0,
            commentCount: 0,
            shareCount: 0,
            isLiked: false,
            tags: []
        )
        posts.insert(newPost, at: 0)
        applySnapshot(animated: true)
    }

    private func toggleLike(postID: SocialPost.ID) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[postIndex].isLiked.toggle()
        posts[postIndex].likeCount += posts[postIndex].isLiked ? 1 : -1

        let rowIndex = dataSource.snapshot().indexOfItem(postID)
        guard let rowIndex else { return }
        let cellView = tableView.view(atColumn: 0, row: rowIndex, makeIfNecessary: false) as? PostTableCellView
        cellView?.configure(with: posts[postIndex])
    }
}
