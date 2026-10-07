import UIKit

/// Two-column chat, matching the SwiftUI example's `NavigationSplitView`.
final class ChatSplitViewController: UISplitViewController {
    private let store = ChatStore()
    private var hasSelectedConversation = false

    init() {
        super.init(style: .doubleColumn)

        let listViewController = ConversationListViewController(store: store)
        listViewController.onSelectConversation = { [weak self] identifier in
            self?.showConversation(identifier)
        }

        setViewController(UINavigationController(rootViewController: listViewController), for: .primary)
        setViewController(UINavigationController(rootViewController: ConversationPlaceholderViewController()), for: .secondary)

        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        presentsWithGesture = true
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showConversation(_ identifier: Conversation.ID) {
        hasSelectedConversation = true
        let detailViewController = ConversationDetailViewController(store: store, conversationID: identifier)
        setViewController(UINavigationController(rootViewController: detailViewController), for: .secondary)
        show(.secondary)
    }
}

extension ChatSplitViewController: UISplitViewControllerDelegate {
    /// On a compact width the split view collapses to one column. Until a
    /// conversation is picked, that column must be the list — not the empty
    /// placeholder.
    func splitViewController(
        _: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        hasSelectedConversation ? proposedTopColumn : .primary
    }
}

/// The empty state shown before a conversation is picked.
final class ConversationPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DemoPalette.groupedBackground

        let symbolImageView = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right"))
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.tintColor = DemoPalette.tertiaryLabel
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        symbolImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel(
            text: "No Conversation Selected",
            font: .preferredFont(forTextStyle: .title3).withWeight(.semibold),
            color: DemoPalette.primaryLabel,
            alignment: .center
        )
        let subtitleLabel = UILabel(
            text: "Choose a conversation from the list.",
            font: .preferredFont(forTextStyle: .subheadline),
            color: DemoPalette.secondaryLabel,
            alignment: .center,
            numberOfLines: 0
        )

        let columnStackView = UIStackView(
            axis: .vertical,
            spacing: 16,
            alignment: .center,
            arrangedSubviews: [symbolImageView, titleLabel, subtitleLabel]
        )
        view.addSubview(columnStackView)

        NSLayoutConstraint.activate([
            columnStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            columnStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            columnStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])
    }
}
