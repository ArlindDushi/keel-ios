import UIKit

/// Creates the Home scene and connects the VIP cycle: view → interactor → presenter → view.
@MainActor
enum HomeConfigurator {
    static func configure(dependencies: DependencyContainer) -> UIViewController {
        let viewController = HomeViewController()
        let interactor = HomeInteractor(worker: HomeWorker(itemService: dependencies.itemService))
        let presenter = HomePresenter()
        let router = HomeRouter()

        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.display = viewController
        router.viewController = viewController
        router.dataStore = interactor
        return viewController
    }
}
