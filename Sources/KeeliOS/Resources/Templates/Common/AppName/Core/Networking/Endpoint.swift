import Foundation

/// Describes one API call. Create them in the service that owns the feature, for example:
///
///     extension Endpoint {
///         static let items = Endpoint(path: "items")
///     }
struct Endpoint: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    var path: String
    var method: Method = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?

    static func json(_ path: String, method: Method, body: some Encodable) throws -> Endpoint {
        Endpoint(path: path, method: method, body: try JSONEncoder.api.encode(body))
    }

    func urlRequest(baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
