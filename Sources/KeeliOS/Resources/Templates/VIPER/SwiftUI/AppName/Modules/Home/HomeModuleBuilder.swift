import SwiftUI

/// Creates the Home module and connects its parts.
@MainActor
enum HomeModuleBuilder {
    static func build(dependencies: DependencyContainer) -> some View {
        HomeView(
            presenter: HomePresenter(interactor: HomeInteractor(itemService: dependencies.itemService)),
            router: HomeRouter()
        )
    }
}
