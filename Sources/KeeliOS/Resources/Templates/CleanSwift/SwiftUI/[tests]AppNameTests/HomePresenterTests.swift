import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomePresenterTests {
    private final class DisplaySpy: HomeDisplayLogic {
        var itemsViewModel: Home.FetchItems.ViewModel?
        var errorViewModel: Home.FetchItems.ErrorViewModel?

        func displayItems(viewModel: Home.FetchItems.ViewModel) { itemsViewModel = viewModel }
        func displayError(viewModel: Home.FetchItems.ErrorViewModel) { errorViewModel = viewModel }
        func displaySelectedItem(viewModel: Home.SelectItem.ViewModel) {}
    }

    @Test func presentsDisplayedItems() {
        let display = DisplaySpy()
        let presenter = HomePresenter()
        presenter.display = display

        presenter.presentItems(response: Home.FetchItems.Response(result: .success(Item.samples)))

        #expect(display.itemsViewModel?.displayedItems.map(\.title) == Item.samples.map(\.title))
    }

    @Test func presentsErrors() {
        let display = DisplaySpy()
        let presenter = HomePresenter()
        presenter.display = display

        presenter.presentItems(response: Home.FetchItems.Response(result: .failure(APIError.invalidResponse)))

        #expect(display.errorViewModel?.message == APIError.invalidResponse.localizedDescription)
    }
}
