import SwiftUI

@main
struct {{APP_NAME}}App: App {
    private let dependencies = DependencyContainer()

    init() {
        ThirdPartyServices.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeConfigurator.configure(dependencies: dependencies)
            }
        }
    }
}
