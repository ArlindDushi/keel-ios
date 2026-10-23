import UIKit

@MainActor
final class AppCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []

    private let window: UIWindow
    private let dependencies: DependencyContainer
    private let navigationController = UINavigationController()

    init(window: UIWindow, dependencies: DependencyContainer) {
        self.window = window
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = HomeViewModel(itemService: dependencies.itemService)
        viewModel.onSelectItem = { [weak self] item in
            self?.showDetail(of: item)
        }
        navigationController.setViewControllers([HomeViewController(viewModel: viewModel)], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

private extension AppCoordinator {
    func showDetail(of item: Item) {
        let viewController = ItemDetailViewController(viewModel: ItemDetailViewModel(item: item))
        navigationController.pushViewController(viewController, animated: true)
    }
}
