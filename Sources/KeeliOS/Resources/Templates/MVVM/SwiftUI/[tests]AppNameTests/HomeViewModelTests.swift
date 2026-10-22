import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomeViewModelTests {
    @Test func loadShowsItems() async {
        let viewModel = HomeViewModel(itemService: MockItemService(), router: Router())

        await viewModel.load()

        #expect(viewModel.state == .loaded(Item.samples))
    }

    @Test func loadShowsFailure() async {
        let error = APIError.invalidResponse
        let viewModel = HomeViewModel(itemService: MockItemService(result: .failure(error)), router: Router())

        await viewModel.load()

        #expect(viewModel.state == .failed(error.localizedDescription))
    }

    @Test func selectingAnItemPushesItsDetail() {
        let router = Router()
        let viewModel = HomeViewModel(itemService: MockItemService(), router: router)

        viewModel.select(Item.samples[0])

        #expect(router.path == [.itemDetail(Item.samples[0])])
    }
}
