import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, data: Data?)
    case decoding(any Error)
    case transport(any Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "The request URL is invalid."
        case .invalidResponse: "The server sent an invalid response."
        case let .httpStatus(code, _): "The server responded with status \(code)."
        case .decoding: "The server response couldn't be read."
        case let .transport(error): error.localizedDescription
        }
    }
}
