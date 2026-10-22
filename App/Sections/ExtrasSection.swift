import KeeliOS
import SwiftUI

struct ExtrasSection: View {
    @Environment(ProjectFormModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section("Tooling") {
            Toggle(isOn: $model.extras.swiftLint) {
                Text("SwiftLint")
                Text("Adds .swiftlint.yml and a build phase that lints on every build.")
            }
            Toggle(isOn: $model.extras.tests) {
                Text("Unit and UI tests")
                Text("Swift Testing unit tests and an XCUITest target, run by every scheme.")
            }
            Toggle(isOn: $model.extras.fastlane) {
                Text("fastlane")
                Text("Gemfile and a Fastfile with a TestFlight lane per environment.")
            }
            Toggle(isOn: $model.extras.gitInit) {
                Text("Git repository")
                Text("Initializes git on main with an initial commit.")
            }
            Toggle(isOn: $model.extras.keepProjectSpec) {
                Text("Keep project.yml")
                Text("Lets you regenerate the project later with the XcodeGen command-line tool.")
            }
            Toggle(isOn: $model.openInXcode) {
                Text("Open in Xcode when done")
            }
        }
    }
}
