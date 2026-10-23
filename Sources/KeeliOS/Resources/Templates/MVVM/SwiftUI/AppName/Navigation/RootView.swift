import SwiftUI

/// Hosts the navigation stack and builds the screen for each `Route`.
struct RootView: View {
    let dependencies: DependencyContainer
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: HomeViewModel(itemService: dependencies.itemService, router: router))
                .navigationDestination(for: Route.self, destination: destination)
        }
    }
}

private extension RootView {
    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case let .itemDetail(item):
            ItemDetailView(viewModel: ItemDetailViewModel(item: item))
        }
    }
}
