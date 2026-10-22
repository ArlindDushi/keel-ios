import ComposableArchitecture
import SwiftUI

@main
struct {{APP_NAME}}App: App {
    @MainActor
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        ThirdPartyServices.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
