import UIKit

/// A display-only scene: without business logic it needs no interactor, presenter or router.
@MainActor
enum ItemDetailConfigurator {
    static func configure(item: Item) -> UIViewController {
        ItemDetailViewController(item: item)
    }
}
