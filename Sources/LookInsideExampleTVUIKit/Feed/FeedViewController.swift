import TVUIKit
import UIKit

/// The Feed screen: one `UICollectionView` with two sideways-scrolling
/// shelves. Stories use TVUIKit's monogram content configuration; posts are
/// hand-built cards that lift themselves when focused. Pressing a post likes
/// it.
final class FeedViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case stories
        case posts

        var title: String {
            switch self {
            case .stories: "Stories"
            case .posts: "Latest Posts"
            }
        }
    }

    private enum Item: Hashable {
        case story(SocialStory.ID)
        case post(SocialPost.ID)
    }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private var posts = SocialPost.samples
    private let stories = SocialStory.samples

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.pinEdges(to: view)

        buildDataSource()
        applyInitialSnapshot()
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            let itemSize = switch section {
            case .stories: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(300))
            case .posts: NSCollectionLayoutSize(widthDimension: .absolute(640), heightDimension: .absolute(520))
            }
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [NSCollectionLayoutItem(layoutSize: itemSize)])
            let layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.orthogonalScrollingBehavior = .continuous
            layoutSection.interGroupSpacing = DemoMetrics.shelfSpacing
            // Room above and below for a card lifted by focus.
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: DemoMetrics.sectionSpacing, trailing: 0)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
            layoutSection.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )]
            return layoutSection
        }
    }

    // MARK: - Data source

    private func buildDataSource() {
        let storyRegistration = UICollectionView.CellRegistration<UICollectionViewCell, SocialStory> { cell, _, story in
            var configuration = TVMonogramContentConfiguration.cell()
            configuration.image = ArtworkImage.monogram(initials: story.initials, tint: story.tint.color, side: 200)
            configuration.text = story.name
            configuration.secondaryText = story.isUnseen ? "New" : nil
            cell.contentConfiguration = configuration
        }

        let postRegistration = UICollectionView.CellRegistration<PostCell, SocialPost> { cell, _, post in
            cell.configure(with: post)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case let .story(storyIdentifier):
                let story = self?.stories.first { $0.id == storyIdentifier }
                return collectionView.dequeueConfiguredReusableCell(using: storyRegistration, for: indexPath, item: story)
            case let .post(postIdentifier):
                let post = self?.posts.first { $0.id == postIdentifier }
                return collectionView.dequeueConfiguredReusableCell(using: postRegistration, for: indexPath, item: post)
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { headerView, _, indexPath in
            headerView.titleLabel.text = Section(rawValue: indexPath.section)?.title
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }

    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(stories.map { .story($0.id) }, toSection: .stories)
        snapshot.appendItems(posts.map { .post($0.id) }, toSection: .posts)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension FeedViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case let .post(postIdentifier) = dataSource.itemIdentifier(for: indexPath),
              let postIndex = posts.firstIndex(where: { $0.id == postIdentifier })
        else { return }

        posts[postIndex].isLiked.toggle()
        posts[postIndex].likeCount += posts[postIndex].isLiked ? 1 : -1

        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([.post(postIdentifier)])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
