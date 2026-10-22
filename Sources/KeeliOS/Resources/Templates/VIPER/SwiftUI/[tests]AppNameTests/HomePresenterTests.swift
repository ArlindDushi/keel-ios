import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomePresenterTests {
    @Test func loadingShowsItems() async {
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: MockItemService()))

        await presenter.loadItems()

        #expect(presenter.items.map(\.title) == Item.samples.map(\.title))
        #expect(!presenter.isLoading)
    }

    @Test func failureShowsError() async {
        let service = MockItemService(result: .failure(APIError.invalidResponse))
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: service))

        await presenter.loadItems()

        #expect(presenter.errorMessage == APIError.invalidResponse.localizedDescription)
    }

    @Test func selectingAnItemShowsItsDetail() async throws {
        let presenter = HomePresenter(interactor: HomeInteractor(itemService: MockItemService()))
        await presenter.loadItems()

        presenter.didSelect(try #require(presenter.items.first))

        #expect(presenter.selectedItem == Item.samples.first)
    }
}
