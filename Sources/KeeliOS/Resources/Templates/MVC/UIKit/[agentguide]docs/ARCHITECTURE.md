# Architecture: MVC (UIKit)

{{APP_NAME}} uses Apple's Model-View-Controller with UIKit. Each screen has a **view controller** that
owns its logic, a **view** that only lays out subviews, and **models** that are plain values.
Services do the data work and are injected into view controllers.

Rules:
- Views never call services and never know about other screens. They expose subviews and small
  setters like `setLoading(_:)`.
- View controllers get their dependencies through `init`. They never create services and never read
  `DependencyContainer`.
- Models (`Item`) are `Sendable` value types with no UIKit imports.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── AppDelegate.swift           Launch; calls ThirdPartyServices.configure()
│   ├── SceneDelegate.swift         Creates the window and the root navigation controller
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Core/                           Networking, Environment, DesignSystem, Extensions (shared)
├── Features/
│   ├── Home/
│   │   ├── HomeViewController.swift   Loads items, table data source/delegate, navigation
│   │   └── HomeView.swift             UIView with the table view and the loading indicator
│   └── ItemDetail/
│       ├── ItemDetailViewController.swift
│       └── ItemDetailContentView.swift
├── Models/
│   └── Item.swift
├── Services/
│   └── ItemService.swift           ItemServicing protocol + ItemService
└── Resources/
```

New screens go in `Features/<Feature>/` as `<Feature>ViewController.swift` and `<Feature>View.swift`.
Use `<Feature>ContentView.swift` for the view when `<Feature>View` would clash with another type. New
models go in `Models/` and new services in `Services/`.

## Responsibilities

| Type | Does | Doesn't |
|---|---|---|
| `HomeViewController` | Owns `items`, calls `itemService.fetchItems()`, is the table's data source and delegate, shows errors, pushes the next screen | Lay out subviews (that's `HomeView`) |
| `HomeView` | Builds and lays out `tableView` and the spinner; `setLoading(_:)` | Hold data or call services |
| `ItemService` (`ItemServicing`) | Fetches data through `APIClientProtocol` | Touch UIKit |
| `Item` | Plain data | Contain logic that needs services |

## Communication

```
SceneDelegate ──owns──▶ DependencyContainer
      │
      └─ creates ─▶ HomeViewController(itemService:)
                        │ strong
                        ├──────────▶ any ItemServicing ──▶ APIClient
                        │ strong (loadView: view = homeView)
                        └──────────▶ HomeView ── tableView.dataSource/delegate = controller
```

- The controller loads data in `viewDidLoad` with `Task { await loadItems() }`. It sets
  `homeView.setLoading(_:)` around the call and stores the result in `items`, whose `didSet` reloads
  the table.
- User input reaches the controller through UIKit delegates (`UITableViewDelegate`) or target-action.
  It does not use closures stored on the view.
- Errors are shown with `UIAlertController` in `showError(_:)`. The retry action captures
  `[weak self]`.
- Data moves forward through initializers, e.g. `ItemDetailViewController(item:)`. To send results
  back, give the child a delegate protocol (`weak var delegate: <Feature>ViewControllerDelegate?`) or a
  completion closure, and have the presenting controller react to it.

## Routing

Navigation is done by the view controller that owns the transition:

```swift
// HomeViewController: UITableViewDelegate
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let detail = ItemDetailViewController(item: items[indexPath.row])
    navigationController?.pushViewController(detail, animated: true)
}
```

- **Root:** `SceneDelegate.scene(_:willConnectTo:options:)` sets
  `window.rootViewController = UINavigationController(rootViewController: home)`.
- **Push** with `navigationController?.pushViewController(_:animated:)`. **Present** modally with
  `present(_:animated:)`, wrapping the controller in a `UINavigationController` if it needs a bar.
- If the next screen needs a service, the current controller must already have it so it can pass it
  on, e.g. `SettingsViewController(itemService: itemService)`. When a chain of screens needs many
  services, inject `DependencyContainer` into the controller that starts the chain. Don't create it
  again.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`SceneDelegate` owns the container and passes services into the root controller's `init`. Everything
else is passed down from there.

## Adding a feature

1. Add the model to `Models/` and the service to `Services/`: a `Sendable` protocol plus a struct that
   takes `any APIClientProtocol`. Create the service in `DependencyContainer`.
2. Create `Features/<Feature>/<Feature>View.swift`, a `UIView` subclass that builds its subviews in
   `init(frame:)`, lays them out with `Spacing` and the `UIView+Layout` helpers, and exposes them as
   `let` properties.
3. Create `Features/<Feature>/<Feature>ViewController.swift`:

   ```swift
   final class SettingsViewController: UIViewController {
       private let settingsService: any SettingsServicing
       private let settingsView = SettingsView()

       init(settingsService: any SettingsServicing) {
           self.settingsService = settingsService
           super.init(nibName: nil, bundle: nil)
       }

       @available(*, unavailable)
       required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }

       override func loadView() {
           view = settingsView
       }

       override func viewDidLoad() {
           super.viewDidLoad()
           title = String(localized: "Settings")
           Task { await load() }
       }
   }
   ```

4. Push or present it from the screen that leads to it, passing its dependencies in.
5. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `ItemServiceTests.swift` is the sample.

- **Services:** call the real service, or inject a fake `APIClientProtocol` to return fixed data.
- **View controllers:** create them with `MockItemService` (`Mocks/MockItemService.swift`), call
  `loadViewIfNeeded()`, wait for the load, then assert on the view (e.g. the number of table rows).
  For navigation, embed the controller in a `UINavigationController` and assert on `viewControllers`.
- Mark the test struct `@MainActor` when it touches UIKit.

```swift
@MainActor
struct HomeViewControllerTests {
    @Test func showsItems() async throws {
        let controller = HomeViewController(itemService: MockItemService())
        controller.loadViewIfNeeded()
        // wait for the load task, then assert on the table view
    }
}
```

To make a controller easier to test, keep logic in small methods you can call directly. Don't
reach into private subviews.

{{/if}}
## Do and don't

- **Do** keep view controllers small. Move formatting, validation and data shaping into the model or
  a service as a controller grows.
- **Do** keep views dumb: no service calls and no navigation in `UIView` subclasses.
- **Don't** use singletons or create `DependencyContainer()` inside a feature.
- **Don't** add storyboards or XIBs. Everything is built in code.
- **Don't** forget `[weak self]` in closures stored by UIKit (alert actions, notifications, timers).
