import AppKit

/// Which screen the detail pane is showing.
enum DemoDestination: String, CaseIterable {
    case music
    case feed
    case chat
    case controls
    case status

    var title: String {
        switch self {
        case .music: "Music"
        case .feed: "Feed"
        case .chat: "Chat"
        case .controls: "Controls"
        case .status: "Status"
        }
    }

    var symbolName: String {
        switch self {
        case .music: "play.circle"
        case .feed: "square.text.square"
        case .chat: "bubble.left.and.bubble.right"
        case .controls: "slider.horizontal.3"
        case .status: "info.circle"
        }
    }
}

/// Sidebar + detail, the standard shape of a Mac app window.
final class RootSplitViewController: NSSplitViewController {
    private let sidebarViewController = SidebarViewController()
    private let detailContainerViewController = DetailContainerViewController()

    private lazy var musicPlayerViewController = MusicPlayerViewController()
    private lazy var socialFeedViewController = SocialFeedViewController()
    private lazy var chatViewController = ChatViewController()
    private lazy var controlsViewController = ControlsViewController()
    private lazy var statusViewController = StatusViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 280
        sidebarItem.canCollapse = true
        addSplitViewItem(sidebarItem)

        let detailItem = NSSplitViewItem(viewController: detailContainerViewController)
        detailItem.minimumThickness = 520
        addSplitViewItem(detailItem)

        sidebarViewController.onSelectDestination = { [weak self] destination in
            self?.show(destination)
        }
        show(.music)
    }

    private func show(_ destination: DemoDestination) {
        let destinationViewController: NSViewController = switch destination {
        case .music: musicPlayerViewController
        case .feed: socialFeedViewController
        case .chat: chatViewController
        case .controls: controlsViewController
        case .status: statusViewController
        }
        detailContainerViewController.show(destinationViewController)
        view.window?.subtitle = destination.title
    }

    @objc
    func refreshLicenseState(_: Any?) {
        statusViewController.refreshLicenseState()
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
