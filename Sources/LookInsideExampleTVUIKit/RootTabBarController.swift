import UIKit

/// The tab bar along the top of the screen. Each tab holds its screen
/// directly: Apple TV apps do not stack a navigation bar under the tab bar.
final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let welcomeViewController = WelcomeViewController()
        welcomeViewController.tabBarItem = UITabBarItem(title: "Welcome", image: nil, tag: 0)

        let musicViewController = MusicViewController()
        musicViewController.tabBarItem = UITabBarItem(title: "Music", image: nil, tag: 1)

        let feedViewController = FeedViewController()
        feedViewController.tabBarItem = UITabBarItem(title: "Feed", image: nil, tag: 2)

        let controlsViewController = ControlsViewController()
        controlsViewController.tabBarItem = UITabBarItem(title: "Controls", image: nil, tag: 3)

        // Order matches `WelcomeViewController.DemoTab`.
        viewControllers = [
            welcomeViewController,
            musicViewController,
            feedViewController,
            controlsViewController,
        ]
    }
}
