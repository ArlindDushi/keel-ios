import Testing
@testable import {{APP_NAME}}

struct ItemServiceTests {
    @Test func fetchItemsReturnsItems() async throws {
        let items = try await ItemService().fetchItems()
        #expect(!items.isEmpty)
    }
}
