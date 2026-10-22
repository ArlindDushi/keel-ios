import Foundation
import Observation

@MainActor
@Observable
final class ItemDetailViewModel {
    private let item: Item

    init(item: Item) {
        self.item = item
    }

    var title: String { item.title }
    var subtitle: String { item.subtitle }
}
