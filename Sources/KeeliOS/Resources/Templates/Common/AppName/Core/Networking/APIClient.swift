{{#if has_Alamofire}}
import Alamofire
{{/if}}
import Foundation

/// Sends requests to the current environment's API. Features use it through services,
/// so it can be replaced with a mock in tests and previews.
protocol APIClientProtocol: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response
}

struct APIClient: APIClientProtocol {
    private let baseURL: URL
{{#if has_Alamofire}}
    private let session: Session

    init(baseURL: URL = AppEnvironment.apiBaseURL, session: Session = .default) {
        self.baseURL = baseURL
        self.session = session
    }

    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let request = try endpoint.urlRequest(baseURL: baseURL)
        let response = await session.request(request)
            .validate()
            .serializingDecodable(Response.self, decoder: JSONDecoder.api)
            .response
        switch response.result {
        case let .success(value):
            return value
        case let .failure(error):
            if let statusCode = response.response?.statusCode, !(200..<300).contains(statusCode) {
                throw APIError.httpStatus(statusCode, data: response.data)
            }
            if case .responseSerializationFailed = error {
                throw APIError.decoding(error)
            }
            throw APIError.transport(error)
        }
    }
{{else}}
    private let session: URLSession

    init(baseURL: URL = AppEnvironment.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let request = try endpoint.urlRequest(baseURL: baseURL)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode, data: data)
        }
        do {
            return try JSONDecoder.api.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
{{/if}}
}
