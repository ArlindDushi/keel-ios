import UIKit

/// Owns a flow of screens and decides what comes next, so view controllers don't push each other.
@MainActor
protocol Coordinator: AnyObject {
    var childCoordinators: [any Coordinator] { get set }
    func start()
}

extension Coordinator {
    func addChild(_ coordinator: any Coordinator) {
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    func removeChild(_ coordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}
