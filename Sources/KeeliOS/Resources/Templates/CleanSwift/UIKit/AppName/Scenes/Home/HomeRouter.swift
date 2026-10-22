import UIKit

@MainActor
protocol HomeRoutingLogic: AnyObject {
    func routeToItemDetail()
}

@MainActor
protocol HomeDataPassing: AnyObject {
    var dataStore: (any HomeDataStore)? { get }
}

@MainActor
final class HomeRouter: HomeRoutingLogic, HomeDataPassing {
    weak var viewController: UIViewController?
    var dataStore: (any HomeDataStore)?

    func routeToItemDetail() {
        guard let item = dataStore?.selectedItem else { return }
        viewController?.navigationController?.pushViewController(ItemDetailConfigurator.configure(item: item), animated: true)
    }
}
