import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomePresenterTests {
    private final class ViewSpy: HomeViewProtocol {
        var displayedItems: [HomeItemViewModel] = []
        var errorMessage: String?

        func display(_ items: [HomeItemViewModel]) { displayedItems = items }
        func displayLoading(_ isLoading: Bool) {}
        func displayError(_ message: String) { errorMessage = message }
    }

    private final class RouterSpy: HomeRouterProtocol {
        var shownItem: Item?

        func showDetail(of item: Item) { shownItem = item }
    }

    @Test func loadingDisplaysItems() async {
        let view = ViewSpy()
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: MockItemService()), router: RouterSpy())
        presenter.view = view

        await presenter.loadItems()

        #expect(view.displayedItems.map(\.title) == Item.samples.map(\.title))
    }

    @Test func failureDisplaysError() async {
        let view = ViewSpy()
        let service = MockItemService(result: .failure(APIError.invalidResponse))
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: service), router: RouterSpy())
        presenter.view = view

        await presenter.loadItems()

        #expect(view.errorMessage == APIError.invalidResponse.localizedDescription)
    }

    @Test func selectingAnItemRoutesToDetail() async {
        let router = RouterSpy()
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: MockItemService()), router: router)
        await presenter.loadItems()

        presenter.didSelectItem(at: 1)

        #expect(router.shownItem == Item.samples[1])
    }
}
