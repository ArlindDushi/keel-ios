import SwiftUI

struct HomeView: View {
    @State private var state: HomeViewState
    // The VIP objects live in @State so they survive view updates together.
    @State private var interactor: any HomeBusinessLogic
    @State private var router: HomeRouter

    init(state: HomeViewState, interactor: any HomeBusinessLogic, router: HomeRouter) {
        _state = State(initialValue: state)
        _interactor = State(initialValue: interactor)
        _router = State(initialValue: router)
    }

    var body: some View {
        content
            .navigationTitle("Home")
            .navigationDestination(isPresented: $state.isShowingItemDetail) {
                router.itemDetail()
            }
            .task {
                guard state.displayedItems.isEmpty else { return }
                await fetchItems()
            }
    }
}

private extension HomeView {
    @ViewBuilder
    var content: some View {
        if let message = state.errorMessage {
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await fetchItems() }
                }
            }
        } else if state.isLoading && state.displayedItems.isEmpty {
            ProgressView()
        } else {
            List(Array(state.displayedItems.enumerated()), id: \.offset) { index, item in
                Button {
                    interactor.selectItem(request: Home.SelectItem.Request(index: index))
                } label: {
                    ItemRow(title: item.title, subtitle: item.subtitle)
                }
                .foregroundStyle(.primary)
            }
        }
    }

    func fetchItems() async {
        state.isLoading = true
        await interactor.fetchItems(request: Home.FetchItems.Request())
    }
}

#Preview {
    NavigationStack {
        HomeConfigurator.configure(dependencies: DependencyContainer())
    }
}
