import Foundation

extension JSONDecoder {
    /// Decoder matching the API's conventions: snake_case keys and ISO 8601 dates.
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    /// Encoder matching the API's conventions: snake_case keys and ISO 8601 dates.
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
