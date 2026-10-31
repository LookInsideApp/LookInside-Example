import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let newWindow = UIWindow(windowScene: windowScene)
        newWindow.tintColor = DemoPalette.accent
        newWindow.rootViewController = RootTabBarController()
        newWindow.makeKeyAndVisible()
        window = newWindow
    }
}
