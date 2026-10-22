import UIKit

/// A display-only module: without business logic or navigation it needs no interactor or router.
@MainActor
enum ItemDetailModuleBuilder {
    static func build(item: Item) -> UIViewController {
        ItemDetailViewController(item: item)
    }
}
