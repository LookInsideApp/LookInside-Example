import UIKit

/// The feed screen: one `UICollectionView` driven by a compositional layout and
/// a diffable data source.
///
/// Three sections with different behaviour — an orthogonally scrolling stories
/// strip, a self-sizing composer, and a list of self-sizing post cards — which
/// is what makes the layout worth inspecting from the host.
final class SocialFeedViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case stories
        case composer
        case posts
    }

    private enum Item: Hashable {
        case addStory
        case story(SocialStory.ID)
        case composer
        case post(SocialPost.ID)
    }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private var posts = SocialPost.samples
    private let stories = SocialStory.samples

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Feed"
        view.backgroundColor = DemoPalette.groupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            menu: UIMenu(children: [
                UIAction(title: "Latest", image: UIImage(systemName: "clock")) { _ in },
                UIAction(title: "Following", image: UIImage(systemName: "person.2")) { _ in },
                UIAction(title: "Trending", image: UIImage(systemName: "flame")) { _ in },
            ])
        )

        buildCollectionView()
        buildDataSource()
        applySnapshot(animated: false)
    }

    // MARK: - Collection view

    private func buildCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = DemoPalette.groupedBackground
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        view.addSubview(collectionView)
        collectionView.pinEdges(to: view)
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            let availableWidth = layoutEnvironment.container.effectiveContentSize.width
            let horizontalInset = max(16, (availableWidth - DemoMetrics.contentMaximumWidth) / 2)

            switch section {
            case .stories:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(74),
                    heightDimension: .absolute(100)
                ))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .absolute(74),
                        heightDimension: .absolute(100)
                    ),
                    subitems: [item]
                )
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.orthogonalScrollingBehavior = .continuous
                layoutSection.interGroupSpacing = 14
                layoutSection.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: horizontalInset,
                    bottom: 8,
                    trailing: horizontalInset
                )
                return layoutSection

            case .composer, .posts:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(section == .composer ? 96 : 260)
                ))
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(section == .composer ? 96 : 260)
                    ),
                    subitems: [item]
                )
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.interGroupSpacing = 16
                layoutSection.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: horizontalInset,
                    bottom: section == .posts ? 24 : 0,
                    trailing: horizontalInset
                )
                return layoutSection
            }
        }
    }

    private func buildDataSource() {
        let addStoryRegistration = UICollectionView.CellRegistration<AddStoryCell, Item> { _, _, _ in }

        let storyRegistration = UICollectionView.CellRegistration<StoryBubbleCell, SocialStory> { cell, _, story in
            cell.configure(with: story)
        }

        let composerRegistration = UICollectionView.CellRegistration<ComposerCell, Item> { [weak self] cell, _, _ in
            cell.onHeightChange = { [weak self] in
                self?.invalidateComposerLayout()
            }
            cell.onPublish = { [weak self] body in
                self?.publishPost(body: body)
            }
        }

        let postRegistration = UICollectionView.CellRegistration<PostCell, SocialPost> { [weak self] cell, _, post in
            cell.configure(with: post)
            cell.onToggleLike = { [weak self] in
                self?.toggleLike(postID: post.id)
            }
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case .addStory:
                return collectionView.dequeueConfiguredReusableCell(using: addStoryRegistration, for: indexPath, item: item)
            case let .story(storyID):
                guard let story = self?.stories.first(where: { $0.id == storyID }) else { return nil }
                return collectionView.dequeueConfiguredReusableCell(using: storyRegistration, for: indexPath, item: story)
            case .composer:
                return collectionView.dequeueConfiguredReusableCell(using: composerRegistration, for: indexPath, item: item)
            case let .post(postID):
                guard let post = self?.posts.first(where: { $0.id == postID }) else { return nil }
                return collectionView.dequeueConfiguredReusableCell(using: postRegistration, for: indexPath, item: post)
            }
        }
    }

    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.addStory] + stories.map { Item.story($0.id) }, toSection: .stories)
        snapshot.appendItems([.composer], toSection: .composer)
        snapshot.appendItems(posts.map { Item.post($0.id) }, toSection: .posts)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Interaction

    private func invalidateComposerLayout() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
    }

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

        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([.post(postID)])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
