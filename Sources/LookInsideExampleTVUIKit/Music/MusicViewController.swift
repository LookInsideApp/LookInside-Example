import TVUIKit
import UIKit

/// The Music screen: one `UICollectionView` with a compositional layout and a
/// diffable data source.
///
/// The first section is a single now-playing cell; the two shelves below use
/// TVUIKit's media item content configuration and its matching orthogonal
/// section, which give the cells the system focus effect.
final class MusicViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case nowPlaying
        case upNext
        case madeForYou

        var title: String? {
            switch self {
            case .nowPlaying: nil
            case .upNext: "Up Next"
            case .madeForYou: "Made for You"
            }
        }
    }

    private enum Item: Hashable {
        case nowPlaying
        case track(MusicTrack.ID)
        case playlist(Playlist.ID)
    }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private var currentTrackIndex = 0
    private var isPlaying = true
    private var isShuffled = false
    private var repeatMode: RepeatMode = .off
    private var playbackFraction: Float = 0.32

    private var currentTrack: MusicTrack {
        MusicTrack.queue[currentTrackIndex]
    }

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

            switch section {
            case .nowPlaying:
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(480))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: DemoMetrics.sectionSpacing, trailing: 0)
                return layoutSection

            case .upNext, .madeForYou:
                let layoutSection = NSCollectionLayoutSection.orthogonalLayoutSectionForMediaItems()
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
                layoutSection.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )]
                return layoutSection
            }
        }
    }

    // MARK: - Data source

    private func buildDataSource() {
        let nowPlayingRegistration = UICollectionView.CellRegistration<NowPlayingCell, Item> { [weak self] cell, _, _ in
            guard let self else { return }
            cell.configure(
                track: currentTrack,
                isPlaying: isPlaying,
                isShuffled: isShuffled,
                repeatMode: repeatMode,
                playbackFraction: playbackFraction
            )
            cell.transportActionHandler = { [weak self] action in
                self?.perform(action)
            }
        }

        let trackRegistration = UICollectionView.CellRegistration<UICollectionViewCell, MusicTrack> { [weak self] cell, _, track in
            guard let self else { return }
            let isCurrentTrack = track.id == currentTrack.id
            var configuration = TVMediaItemContentConfiguration.wideCell()
            configuration.image = ArtworkImage.gradientTile(
                symbolName: track.symbolName,
                tint: track.tint.color,
                size: CGSize(width: 640, height: 360),
                symbolPointSize: 110
            )
            configuration.text = track.title
            configuration.secondaryText = "\(track.artist) · \(DemoDurationFormatter.minuteSecond(track.duration))"
            configuration.playbackProgress = isCurrentTrack ? playbackFraction : 0
            configuration.badgeText = isCurrentTrack ? (isPlaying ? "PLAYING" : "PAUSED") : nil
            cell.contentConfiguration = configuration
        }

        let playlistRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Playlist> { cell, _, playlist in
            var configuration = TVMediaItemContentConfiguration.wideCell()
            configuration.image = ArtworkImage.gradientTile(
                symbolName: playlist.symbolName,
                tint: playlist.tint.color,
                size: CGSize(width: 640, height: 360),
                symbolPointSize: 90
            )
            configuration.text = playlist.name
            configuration.secondaryText = "\(playlist.trackCount) tracks · \(playlist.durationInMinutes) min"
            configuration.badgeText = playlist.subtitle
            cell.contentConfiguration = configuration
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .nowPlaying:
                return collectionView.dequeueConfiguredReusableCell(using: nowPlayingRegistration, for: indexPath, item: item)
            case let .track(trackIdentifier):
                let track = MusicTrack.queue.first { $0.id == trackIdentifier }
                return collectionView.dequeueConfiguredReusableCell(using: trackRegistration, for: indexPath, item: track)
            case let .playlist(playlistIdentifier):
                let playlist = Playlist.samples.first { $0.id == playlistIdentifier }
                return collectionView.dequeueConfiguredReusableCell(using: playlistRegistration, for: indexPath, item: playlist)
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
        snapshot.appendItems([.nowPlaying], toSection: .nowPlaying)
        snapshot.appendItems(MusicTrack.queue.map { .track($0.id) }, toSection: .upNext)
        snapshot.appendItems(Playlist.samples.map { .playlist($0.id) }, toSection: .madeForYou)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Re-runs the cell registrations for the now-playing cell and the track
    /// shelf, keeping the cells (and the focus) where they are.
    private func reconfigurePlaybackItems() {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems(snapshot.itemIdentifiers(inSection: .nowPlaying) + snapshot.itemIdentifiers(inSection: .upNext))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Playback

    private func perform(_ action: NowPlayingCell.TransportAction) {
        switch action {
        case .toggleShuffle:
            isShuffled.toggle()
        case .previous:
            play(max(0, currentTrackIndex - 1))
            return
        case .togglePlayback:
            isPlaying.toggle()
        case .next:
            play(min(MusicTrack.queue.count - 1, currentTrackIndex + 1))
            return
        case .cycleRepeatMode:
            repeatMode = repeatMode.next
        }
        reconfigurePlaybackItems()
    }

    private func play(_ trackIndex: Int) {
        guard trackIndex != currentTrackIndex else { return }
        currentTrackIndex = trackIndex
        playbackFraction = 0
        isPlaying = true
        reconfigurePlaybackItems()
    }
}

extension MusicViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        // Focus goes to the buttons inside the now-playing cell, not the cell.
        Section(rawValue: indexPath.section) != .nowPlaying
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case let .track(trackIdentifier) = dataSource.itemIdentifier(for: indexPath),
              let trackIndex = MusicTrack.queue.firstIndex(where: { $0.id == trackIdentifier })
        else { return }
        play(trackIndex)
    }
}
