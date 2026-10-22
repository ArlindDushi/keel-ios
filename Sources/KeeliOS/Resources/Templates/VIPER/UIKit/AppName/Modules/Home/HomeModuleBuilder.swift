import UIKit

/// Creates the Home module and connects its parts.
@MainActor
enum HomeModuleBuilder {
    static func build(dependencies: DependencyContainer) -> UIViewController {
        let router = HomeRouter()
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: dependencies.itemService), router: router)
        let viewController = HomeViewController(presenter: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return viewController
    }
}
