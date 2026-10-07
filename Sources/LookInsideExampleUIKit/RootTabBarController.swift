import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let welcomeNavigationController = UINavigationController(rootViewController: WelcomeViewController())
        welcomeNavigationController.tabBarItem = UITabBarItem(
            title: "Welcome",
            image: UIImage(systemName: "hand.wave"),
            selectedImage: UIImage(systemName: "hand.wave.fill")
        )

        let musicNavigationController = UINavigationController(rootViewController: MusicPlayerViewController())
        musicNavigationController.tabBarItem = UITabBarItem(
            title: "Music",
            image: UIImage(systemName: "music.note"),
            selectedImage: UIImage(systemName: "music.note")
        )

        let feedNavigationController = UINavigationController(rootViewController: SocialFeedViewController())
        feedNavigationController.tabBarItem = UITabBarItem(
            title: "Feed",
            image: UIImage(systemName: "newspaper"),
            selectedImage: UIImage(systemName: "newspaper.fill")
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

        // Order matches `WelcomeViewController.DemoTab`.
        viewControllers = [
            welcomeNavigationController,
            musicNavigationController,
            feedNavigationController,
            chatSplitViewController,
            controlsNavigationController,
        ]

        for navigationController in viewControllers ?? [] {
            (navigationController as? UINavigationController)?.navigationBar.prefersLargeTitles = true
        }
    }
}
