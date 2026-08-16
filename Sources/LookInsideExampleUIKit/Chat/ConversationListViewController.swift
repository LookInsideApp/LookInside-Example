import UIKit

/// The sidebar list: a plain-style `UITableView` with a search controller and
/// trailing swipe actions, driven by a diffable data source.
final class ConversationListViewController: UIViewController {
    private enum Section {
        case main
    }

    private let store: ChatStore
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private var dataSource: UITableViewDiffableDataSource<Section, Conversation.ID>!

    var onSelectConversation: ((Conversation.ID) -> Void)?

    init(store: ChatStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chats"
        view.backgroundColor = DemoPalette.groupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: nil,
            action: nil
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search messages"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.pinEdges(to: view)

        buildDataSource()
        store.onChange = { [weak self] in
            self?.applySnapshot(animated: true)
        }
        applySnapshot(animated: false)
    }

    private func buildDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Conversation.ID>(tableView: tableView) { [weak self] tableView, indexPath, identifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath)
            guard let conversationCell = cell as? ConversationCell,
                  let conversation = self?.store.conversation(with: identifier)
            else { return cell }
            conversationCell.configure(with: conversation)
            return conversationCell
        }
    }

    private func applySnapshot(animated: Bool) {
        let query = searchController.searchBar.text ?? ""
        var snapshot = NSDiffableDataSourceSnapshot<Section, Conversation.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(store.sortedConversations(matching: query).map(\.id))
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

extension ConversationListViewController: UISearchResultsUpdating {
    func updateSearchResults(for _: UISearchController) {
        applySnapshot(animated: true)
    }
}

extension ConversationListViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        store.markAsRead(identifier)
        onSelectConversation?(identifier)
    }

    func tableView(
        _: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.store.remove(identifier)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let pinAction = UIContextualAction(style: .normal, title: "Pin") { [weak self] _, _, completion in
            self?.store.togglePinned(identifier)
            completion(true)
        }
        pinAction.image = UIImage(systemName: "pin")
        pinAction.backgroundColor = .systemOrange

        return UISwipeActionsConfiguration(actions: [deleteAction, pinAction])
    }
}

/// One conversation row: avatar with an online dot, pin marker, name, preview
/// text and an unread pill.
private final class ConversationCell: UITableViewCell {
    static let reuseIdentifier = "ConversationCell"

    private let avatarBadgeView = AvatarBadgeView(initials: "", tint: .blue, diameter: 48)
    private let onlineIndicatorView = OnlineIndicatorView(ringColor: DemoPalette.cardBackground)
    private let pinImageView = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let nameLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.primaryLabel)
    private let timestampLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .caption1), color: DemoPalette.secondaryLabel, alignment: .right)
    private let previewLabel = UILabel(text: nil, font: .preferredFont(forTextStyle: .subheadline), color: DemoPalette.secondaryLabel, numberOfLines: 2)
    private let unreadBadgeLabel = UILabel(text: nil, font: .systemFont(ofSize: 11, weight: .bold), color: .white, alignment: .center)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        nameLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)

        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(avatarBadgeView)
        avatarContainer.addSubview(onlineIndicatorView)

        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.tintColor = .systemOrange
        pinImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption2)
        pinImageView.setContentHuggingPriority(.required, for: .horizontal)

        timestampLabel.setContentHuggingPriority(.required, for: .horizontal)

        let titleRowStackView = UIStackView(
            axis: .horizontal,
            spacing: 4,
            alignment: .firstBaseline,
            arrangedSubviews: [pinImageView, nameLabel, UIView.flexibleSpacer(), timestampLabel]
        )

        unreadBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadBadgeLabel.backgroundColor = DemoPalette.accent
        unreadBadgeLabel.layer.masksToBounds = true
        unreadBadgeLabel.setContentHuggingPriority(.required, for: .horizontal)

        let previewRowStackView = UIStackView(
            axis: .horizontal,
            spacing: 6,
            alignment: .top,
            arrangedSubviews: [previewLabel, unreadBadgeLabel]
        )

        let textColumnStackView = UIStackView(
            axis: .vertical,
            spacing: 3,
            arrangedSubviews: [titleRowStackView, previewRowStackView]
        )

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .top,
            arrangedSubviews: [avatarContainer, textColumnStackView]
        )
        contentView.addSubview(rowStackView)
        rowStackView.pinEdges(to: contentView, insets: UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))

        NSLayoutConstraint.activate([
            avatarContainer.widthAnchor.constraint(equalToConstant: 48),
            avatarContainer.heightAnchor.constraint(equalToConstant: 48),
            avatarBadgeView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            avatarBadgeView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            onlineIndicatorView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            onlineIndicatorView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            unreadBadgeLabel.heightAnchor.constraint(equalToConstant: 18),
            unreadBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        unreadBadgeLabel.layer.cornerRadius = unreadBadgeLabel.bounds.height / 2
    }

    func configure(with conversation: Conversation) {
        avatarBadgeView.configure(initials: conversation.initials, tint: conversation.tint)
        onlineIndicatorView.isHidden = !conversation.isOnline
        pinImageView.isHidden = !conversation.isPinned
        nameLabel.text = conversation.name
        timestampLabel.text = conversation.timestamp
        timestampLabel.textColor = conversation.unreadCount > 0 ? DemoPalette.accent : DemoPalette.secondaryLabel
        previewLabel.text = conversation.lastMessage
        unreadBadgeLabel.text = conversation.unreadCount > 0 ? " \(conversation.unreadCount) " : nil
        unreadBadgeLabel.isHidden = conversation.unreadCount == 0
    }
}
