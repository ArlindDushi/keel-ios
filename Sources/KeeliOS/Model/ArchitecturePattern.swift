import Foundation

public enum ArchitecturePattern: String, CaseIterable, Codable, Identifiable, Sendable {
    case mvc
    case mvvm
    case viper
    case cleanSwift = "clean_swift"
    case tca

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .mvc: "MVC"
        case .mvvm: "MVVM + Coordinator"
        case .viper: "VIPER"
        case .cleanSwift: "Clean Swift (VIP)"
        case .tca: "The Composable Architecture"
        }
    }

    public var summary: String {
        switch self {
        case .mvc:
            "Apple's classic Model-View-Controller. View controllers own the screen logic; "
                + "views are kept dumb and models plain."
        case .mvvm:
            "View models expose state for the views to render. Navigation lives in coordinators (UIKit) "
                + "or a NavigationStack router (SwiftUI), so screens don't know about each other."
        case .viper:
            "Each module is split into View, Interactor, Presenter, Entity and Router, "
                + "wired together by a module builder through protocol contracts."
        case .cleanSwift:
            "Uncle Bob's Clean Architecture as a unidirectional View → Interactor → Presenter cycle, "
                + "with Request / Response / ViewModel models per use case."
        case .tca:
            "Point-Free's Composable Architecture: state, actions and reducers with "
                + "dependency-injected clients. Adds the swift-composable-architecture package."
        }
    }

    public var supportedFrameworks: [UIFramework] {
        switch self {
        case .mvc: [.uiKit]
        case .tca: [.swiftUI]
        case .mvvm, .viper, .cleanSwift: [.swiftUI, .uiKit]
        }
    }

    public func supports(_ framework: UIFramework) -> Bool {
        supportedFrameworks.contains(framework)
    }

    /// Folder name inside `Templates/`.
    var templateFolder: String {
        switch self {
        case .mvc: "MVC"
        case .mvvm: "MVVM"
        case .viper: "VIPER"
        case .cleanSwift: "CleanSwift"
        case .tca: "TCA"
        }
    }

    /// Packages the pattern can't work without; they're added automatically.
    var requiredPackages: [RemotePackage] {
        switch self {
        case .tca:
            [RemotePackage(
                name: "swift-composable-architecture",
                url: "https://github.com/pointfreeco/swift-composable-architecture",
                requirement: .upToNextMajor("1.26.0"),
                products: ["ComposableArchitecture"]
            )]
        default:
            []
        }
    }
}
