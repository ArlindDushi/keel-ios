import UIKit

@MainActor
final class HomeRouter: HomeRouterProtocol {
    weak var viewController: UIViewController?

    func showDetail(of item: Item) {
        viewController?.navigationController?.pushViewController(ItemDetailModuleBuilder.build(item: item), animated: true)
    }
}
