import Observation

/// Owns the navigation stack. View models navigate through it instead of knowing about other screens.
@MainActor
@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
