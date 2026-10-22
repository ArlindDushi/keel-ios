import UIKit

extension UIView {
    /// Pins all four edges to `other`, optionally inside its safe area.
    func pinEdges(to other: UIView, safeArea: Bool = false) {
        translatesAutoresizingMaskIntoConstraints = false
        let guide: any LayoutGuide = safeArea ? other.safeAreaLayoutGuide : other
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
    }

    func center(in other: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: other.centerXAnchor),
            centerYAnchor.constraint(equalTo: other.centerYAnchor)
        ])
    }
}

/// Lets `pinEdges` accept either a view or a layout guide.
@MainActor
protocol LayoutGuide {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: LayoutGuide {}
extension UILayoutGuide: LayoutGuide {}
