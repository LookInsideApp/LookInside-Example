import AppKit

/// Which screen the detail pane is showing.
enum DemoDestination: String, CaseIterable {
    case welcome
    case music
    case feed
    case chat
    case controls

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .music: "Music"
        case .feed: "Feed"
        case .chat: "Chat"
        case .controls: "Controls"
        }
    }

    var symbolName: String {
        switch self {
        case .welcome: "hand.wave"
        case .music: "music.note"
        case .feed: "newspaper"
        case .chat: "bubble.left.and.bubble.right"
        case .controls: "slider.horizontal.3"
        }
    }

    var filledSymbolName: String {
        switch self {
        case .welcome: "hand.wave.fill"
        case .music: "music.note"
        case .feed: "newspaper.fill"
        case .chat: "bubble.left.and.bubble.right.fill"
        case .controls: "slider.horizontal.3"
        }
    }
}

/// Sidebar + detail, the standard shape of a Mac app window.
final class RootSplitViewController: NSSplitViewController {
    private let sidebarViewController = SidebarViewController()
    private let detailContainerViewController = DetailContainerViewController()

    private lazy var welcomeViewController = WelcomeViewController()
    private lazy var musicPlayerViewController = MusicPlayerViewController()
    private lazy var socialFeedViewController = SocialFeedViewController()
    private lazy var chatViewController = ChatViewController()
    private lazy var controlsViewController = ControlsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 180
        sidebarItem.maximumThickness = 240
        sidebarItem.preferredThicknessFraction = 0.18
        sidebarItem.canCollapse = true
        addSplitViewItem(sidebarItem)

        let detailItem = NSSplitViewItem(viewController: detailContainerViewController)
        detailItem.minimumThickness = 560
        addSplitViewItem(detailItem)

        sidebarViewController.onSelectDestination = { [weak self] destination in
            self?.show(destination)
        }
        welcomeViewController.onSelectDestination = { [weak self] destination in
            self?.sidebarViewController.select(destination)
        }
        show(.welcome)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = currentDestination.title
    }

    private var currentDestination: DemoDestination = .welcome

    private func show(_ destination: DemoDestination) {
        let destinationViewController: NSViewController = switch destination {
        case .welcome: welcomeViewController
        case .music: musicPlayerViewController
        case .feed: socialFeedViewController
        case .chat: chatViewController
        case .controls: controlsViewController
        }
        detailContainerViewController.show(destinationViewController)
        currentDestination = destination
        view.window?.title = destination.title
    }
}

/// Hosts whichever demo screen the sidebar selected, as a real child view
/// controller rather than a swapped-out split view item.
final class DetailContainerViewController: NSViewController {
    private var currentChildViewController: NSViewController?

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView
    }

    func show(_ childViewController: NSViewController) {
        guard currentChildViewController !== childViewController else { return }

        currentChildViewController?.view.removeFromSuperview()
        currentChildViewController?.removeFromParent()

        addChild(childViewController)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childViewController.view)
        childViewController.view.pinEdges(to: view)
        currentChildViewController = childViewController
    }
}
