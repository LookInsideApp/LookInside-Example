import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let musicNavigationController = UINavigationController(rootViewController: MusicPlayerViewController())
        musicNavigationController.tabBarItem = UITabBarItem(
            title: "Music",
            image: UIImage(systemName: "play.circle"),
            selectedImage: UIImage(systemName: "play.circle.fill")
        )

        let feedNavigationController = UINavigationController(rootViewController: SocialFeedViewController())
        feedNavigationController.tabBarItem = UITabBarItem(
            title: "Feed",
            image: UIImage(systemName: "square.text.square"),
            selectedImage: UIImage(systemName: "square.text.square.fill")
        )

        let chatSplitViewController = ChatSplitViewController()
        chatSplitViewController.tabBarItem = UITabBarItem(
            title: "Chat",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )

        let controlsNavigationController = UINavigationController(rootViewController: ControlsViewController())
        controlsNavigationController.tabBarItem = UITabBarItem(
            title: "Controls",
            image: UIImage(systemName: "slider.horizontal.3"),
            selectedImage: UIImage(systemName: "slider.horizontal.3")
        )

        let statusNavigationController = UINavigationController(rootViewController: StatusViewController())
        statusNavigationController.tabBarItem = UITabBarItem(
            title: "Status",
            image: UIImage(systemName: "info.circle"),
            selectedImage: UIImage(systemName: "info.circle.fill")
        )

        viewControllers = [
            musicNavigationController,
            feedNavigationController,
            chatSplitViewController,
            controlsNavigationController,
            statusNavigationController,
        ]

        for navigationController in viewControllers ?? [] {
            (navigationController as? UINavigationController)?.navigationBar.prefersLargeTitles = true
        }
    }
}
