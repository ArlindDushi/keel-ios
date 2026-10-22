import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let dependencies = DependencyContainer()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let home = HomeViewController(itemService: dependencies.itemService)
        window.rootViewController = UINavigationController(rootViewController: home)
        window.makeKeyAndVisible()
        self.window = window
    }
}
