import Foundation

struct Item: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var title: String
    var subtitle: String
}

extension Item {
    static let samples: [Item] = [
        Item(id: UUID(), title: "Welcome to {{DISPLAY_NAME}}", subtitle: "Built with {{PATTERN_NAME}} and {{UI_FRAMEWORK}}"),
        Item(id: UUID(), title: "Environments", subtitle: "Switch schemes to build for another environment"),
        Item(id: UUID(), title: "Next steps", subtitle: "Replace the sample data with a real API call")
    ]
}
