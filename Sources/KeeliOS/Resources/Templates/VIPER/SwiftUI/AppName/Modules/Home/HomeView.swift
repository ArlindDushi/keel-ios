import SwiftUI

struct HomeView<Router: HomeRouterProtocol>: View {
    @State private var presenter: HomePresenter
    private let router: Router

    init(presenter: HomePresenter, router: Router) {
        _presenter = State(initialValue: presenter)
        self.router = router
    }

    var body: some View {
        content
            .navigationTitle("Home")
            .navigationDestination(item: $presenter.selectedItem) { item in
                router.detail(of: item)
            }
            .task { await presenter.onAppear() }
    }
}

private extension HomeView {
    @ViewBuilder
    var content: some View {
        if let message = presenter.errorMessage {
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await presenter.loadItems() }
                }
            }
        } else if presenter.isLoading && presenter.items.isEmpty {
            ProgressView()
        } else {
            List(presenter.items) { item in
                Button {
                    presenter.didSelect(item)
                } label: {
                    ItemRow(title: item.title, subtitle: item.subtitle)
                }
                .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeModuleBuilder.build(dependencies: DependencyContainer())
    }
}
