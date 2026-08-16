import UIKit

/// Two-column chat, matching the SwiftUI example's `NavigationSplitView`.
final class ChatSplitViewController: UISplitViewController {
    private let store = ChatStore()

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
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showConversation(_ identifier: Conversation.ID) {
        let detailViewController = ConversationDetailViewController(store: store, conversationID: identifier)
        setViewController(UINavigationController(rootViewController: detailViewController), for: .secondary)
        show(.secondary)
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
            text: "Pick a conversation",
            font: .preferredFont(forTextStyle: .title3).withWeight(.medium),
            color: DemoPalette.primaryLabel,
            alignment: .center
        )
        let subtitleLabel = UILabel(
            text: "Or start a new one with the compose button.",
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
