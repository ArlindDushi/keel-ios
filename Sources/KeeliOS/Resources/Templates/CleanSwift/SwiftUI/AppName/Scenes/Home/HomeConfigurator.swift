import SwiftUI

/// Creates the Home scene and connects the VIP cycle: view → interactor → presenter → view state.
@MainActor
enum HomeConfigurator {
    static func configure(dependencies: DependencyContainer) -> some View {
        let state = HomeViewState()
        let interactor = HomeInteractor(worker: HomeWorker(itemService: dependencies.itemService))
        let presenter = HomePresenter()
        interactor.presenter = presenter
        presenter.display = state
        return HomeView(state: state, interactor: interactor, router: HomeRouter(dataStore: interactor))
    }
}
