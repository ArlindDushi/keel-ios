import UIKit

/// What the presenter can ask the view to show.
@MainActor
protocol HomeViewProtocol: AnyObject {
    func display(_ items: [HomeItemViewModel])
    func displayLoading(_ isLoading: Bool)
    func displayError(_ message: String)
}

/// User events the view forwards to the presenter.
@MainActor
protocol HomePresenterProtocol: AnyObject {
    func viewDidLoad()
    func didSelectItem(at index: Int)
    func didTapRetry()
}

/// Business logic: fetching and changing data.
protocol HomeInteractorProtocol: Sendable {
    func fetchItems() async throws -> [Item]
}

/// Navigation away from the module.
@MainActor
protocol HomeRouterProtocol: AnyObject {
    func showDetail(of item: Item)
}

/// Display-ready data for one row.
struct HomeItemViewModel: Hashable {
    let title: String
    let subtitle: String
}
