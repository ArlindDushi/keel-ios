import SwiftUI

@main
struct KeelApp: App {
    @State private var model = ProjectFormModel()

    var body: some Scene {
        Window("Keel", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 980, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 820)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
