import Foundation

/// A package offered as a checkbox in the "Remote SDKs" section.
/// The list lives in `Resources/sdk-catalog.json`; add an entry there to offer a new SDK.
public struct SDKCatalogEntry: Identifiable, Hashable, Decodable, Sendable {
    public let id: String
    public let name: String
    public let summary: String
    public let category: String
    public let url: String
    /// Minimum version; the package is added as "up to next major".
    public let version: String
    public let products: [String]
    /// Products selected by default when the package has several.
    public let defaultProducts: [String]
    /// Empty means every UI framework.
    public let uiFrameworks: [UIFramework]
    public let linkerFlags: [String]

    private enum CodingKeys: String, CodingKey {
        case id, name, summary, category, url, version, products, defaultProducts, uiFrameworks, linkerFlags
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decode(String.self, forKey: .summary)
        category = try container.decode(String.self, forKey: .category)
        url = try container.decode(String.self, forKey: .url)
        version = try container.decode(String.self, forKey: .version)
        products = try container.decode([String].self, forKey: .products)
        defaultProducts = try container.decodeIfPresent([String].self, forKey: .defaultProducts) ?? products
        uiFrameworks = try container.decodeIfPresent([UIFramework].self, forKey: .uiFrameworks) ?? []
        linkerFlags = try container.decodeIfPresent([String].self, forKey: .linkerFlags) ?? []
    }

    public func supports(_ framework: UIFramework) -> Bool {
        uiFrameworks.isEmpty || uiFrameworks.contains(framework)
    }

    public func package(products selectedProducts: [String]) -> RemotePackage {
        RemotePackage(
            name: RemotePackage.name(fromURL: url),
            url: url,
            requirement: .upToNextMajor(version),
            products: products.filter(selectedProducts.contains),
            linkerFlags: linkerFlags
        )
    }
}

public enum SDKCatalog {
    public static func load() throws -> [SDKCatalogEntry] {
        guard let url = Bundle.module.url(forResource: "sdk-catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([SDKCatalogEntry].self, from: Data(contentsOf: url))
    }
}
