import Foundation

public enum UIFramework: String, CaseIterable, Codable, Identifiable, Sendable {
    case swiftUI = "swiftui"
    case uiKit = "uikit"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .swiftUI: "SwiftUI"
        case .uiKit: "UIKit"
        }
    }

    /// Folder name inside `Templates/<Pattern>/`.
    var templateFolder: String { displayName }
}
