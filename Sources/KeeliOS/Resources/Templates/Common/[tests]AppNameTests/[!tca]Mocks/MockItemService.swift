import Foundation
@testable import {{APP_NAME}}

struct MockItemService: ItemServicing {
    var result: Result<[Item], any Error> = .success(Item.samples)

    func fetchItems() async throws -> [Item] {
        try result.get()
    }
}
