import UIKit

/// The modal play queue, presented as a sheet with medium and large detents.
/// A classic `UITableViewDataSource` / `UITableViewDelegate` pair with a
/// hand-configured cell, not a `UIContentConfiguration`.
final class QueueViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let currentIndex: Int
    private let onSelectTrack: (Int) -> Void

    init(currentIndex: Int, onSelectTrack: @escaping (Int) -> Void) {
        self.currentIndex = currentIndex
        self.onSelectTrack = onSelectTrack
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Queue"
        view.backgroundColor = DemoPalette.groupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissQueue)
        )

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.register(QueueTrackCell.self, forCellReuseIdentifier: QueueTrackCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
    }

    @objc
    private func dismissQueue() {
        dismiss(animated: true)
    }
}

extension QueueViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        MusicTrack.queue.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: QueueTrackCell.reuseIdentifier, for: indexPath)
        guard let trackCell = cell as? QueueTrackCell else { return cell }
        trackCell.configure(
            position: indexPath.row + 1,
            track: MusicTrack.queue[indexPath.row],
            isCurrent: indexPath.row == currentIndex
        )
        return trackCell
    }
}

extension QueueViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectTrack(indexPath.row)
        dismiss(animated: true)
    }
}

private final class QueueTrackCell: UITableViewCell {
    static let reuseIdentifier = "QueueTrackCell"

    private let positionLabel = UILabel(text: nil, font: .monospacedDigitSystemFont(ofSize: 15, weight: .regular), color: DemoPalette.tertiaryLabel, alignment: .right)
    private let titleLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.primaryLabel)
    private let artistLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1), color: DemoPalette.secondaryLabel)
    private let nowPlayingImageView = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        nowPlayingImageView.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingImageView.contentMode = .scaleAspectFit

        let textStackView = UIStackView(
            axis: .vertical,
            spacing: 2,
            alignment: .leading,
            arrangedSubviews: [titleLabel, artistLabel]
        )

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [positionLabel, textStackView, UIView.flexibleSpacer(), nowPlayingImageView]
        )
        contentView.addSubview(rowStackView)
        rowStackView.pinEdges(to: contentView.layoutMarginsGuide)

        positionLabel.widthAnchor.constraint(equalToConstant: 22).isActive = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(position: Int, track: MusicTrack, isCurrent: Bool) {
        positionLabel.text = "\(position)"
        titleLabel.text = track.title
        artistLabel.text = track.artist
        nowPlayingImageView.isHidden = !isCurrent
        nowPlayingImageView.tintColor = track.tint.color
    }
}
