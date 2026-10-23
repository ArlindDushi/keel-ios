import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Home")
            .task { await viewModel.loadIfNeeded() }
    }
}

private extension HomeView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case let .loaded(items):
            List(items) { item in
                Button {
                    viewModel.select(item)
                } label: {
                    ItemRow(title: item.title, subtitle: item.subtitle)
                }
                .foregroundStyle(.primary)
            }
        case let .failed(message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(itemService: ItemService(), router: Router()))
    }
}
