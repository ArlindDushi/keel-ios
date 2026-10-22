import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomeInteractorTests {
    private final class PresenterSpy: HomePresentationLogic {
        var itemsResponse: Home.FetchItems.Response?
        var selectedResponse: Home.SelectItem.Response?

        func presentItems(response: Home.FetchItems.Response) { itemsResponse = response }
        func presentSelectedItem(response: Home.SelectItem.Response) { selectedResponse = response }
    }

    @Test func fetchItemsPresentsItems() async throws {
        let presenter = PresenterSpy()
        let interactor = HomeInteractor(worker: HomeWorker(itemService: MockItemService()))
        interactor.presenter = presenter

        await interactor.fetchItems(request: Home.FetchItems.Request())

        let items = try #require(presenter.itemsResponse).result.get()
        #expect(items == Item.samples)
    }

    @Test func selectItemStoresAndPresentsTheItem() async {
        let presenter = PresenterSpy()
        let interactor = HomeInteractor(worker: HomeWorker(itemService: MockItemService()))
        interactor.presenter = presenter
        await interactor.fetchItems(request: Home.FetchItems.Request())

        interactor.selectItem(request: Home.SelectItem.Request(index: 2))

        #expect(interactor.selectedItem == Item.samples[2])
        #expect(presenter.selectedResponse?.item == Item.samples[2])
    }
}
