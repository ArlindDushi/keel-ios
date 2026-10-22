import SwiftUI

/// A display-only module: without business logic or navigation it needs no interactor or router.
@MainActor
enum ItemDetailModuleBuilder {
    static func build(item: Item) -> some View {
        ItemDetailView(title: item.title, subtitle: item.subtitle)
    }
}
