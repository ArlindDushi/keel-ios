import Foundation

@MainActor
protocol HomePresentationLogic: AnyObject {
    func presentItems(response: Home.FetchItems.Response)
    func presentSelectedItem(response: Home.SelectItem.Response)
}

@MainActor
final class HomePresenter: HomePresentationLogic {
    weak var display: (any HomeDisplayLogic)?

    func presentItems(response: Home.FetchItems.Response) {
        switch response.result {
        case let .success(items):
            let displayedItems = items.map { Home.FetchItems.ViewModel.DisplayedItem(title: $0.title, subtitle: $0.subtitle) }
            display?.displayItems(viewModel: Home.FetchItems.ViewModel(displayedItems: displayedItems))
        case let .failure(error):
            display?.displayError(viewModel: Home.FetchItems.ErrorViewModel(message: error.localizedDescription))
        }
    }

    func presentSelectedItem(response: Home.SelectItem.Response) {
        display?.displaySelectedItem(viewModel: Home.SelectItem.ViewModel())
    }
}
