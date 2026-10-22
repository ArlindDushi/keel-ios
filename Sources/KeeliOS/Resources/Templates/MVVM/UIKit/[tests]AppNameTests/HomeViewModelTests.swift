import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomeViewModelTests {
    @Test func loadShowsItems() async {
        let viewModel = HomeViewModel(itemService: MockItemService())
        var states: [HomeViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.load()

        #expect(states == [.loading, .loaded(Item.samples)])
    }

    @Test func loadShowsFailure() async {
        let error = APIError.invalidResponse
        let viewModel = HomeViewModel(itemService: MockItemService(result: .failure(error)))

        await viewModel.load()

        #expect(viewModel.state == .failed(error.localizedDescription))
    }

    @Test func selectingAnItemNotifiesTheCoordinator() async {
        let viewModel = HomeViewModel(itemService: MockItemService())
        var selected: Item?
        viewModel.onSelectItem = { selected = $0 }
        await viewModel.load()

        viewModel.selectItem(at: 0)

        #expect(selected == Item.samples[0])
    }
}
