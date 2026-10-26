# Architecture: MVVM + Coordinator (UIKit)

{{APP_NAME}} uses Model-View-ViewModel with UIKit, plus coordinators for navigation:

- **View model:** owns a screen's state and logic.
- **View controller:** renders that state and forwards user input.
- **Coordinator:** owns a flow of screens. It creates view models and view controllers and decides
  what comes next, so screens never know about each other.

Rules:
- View models are `@MainActor final class`es that import only `Foundation`, never `UIKit`. They talk
  outward only through closures: `onStateChange` for the view controller and `on<Event>` for the
  coordinator.
- View controllers never push or present other view controllers, and never create view models for
  other screens.
- Coordinators are the only types that create screens and call `pushViewController` or `present`.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── AppDelegate.swift           Launch; calls ThirdPartyServices.configure()
│   ├── SceneDelegate.swift         Creates the window and starts AppCoordinator
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Coordinators/
│   ├── Coordinator.swift           protocol Coordinator + addChild/removeChild
│   └── AppCoordinator.swift        Root flow: Home → ItemDetail
├── Core/                           Networking, Environment, DesignSystem, Extensions
├── Domain/
│   ├── Models/Item.swift
│   └── Services/ItemService.swift  ItemServicing protocol + ItemService
├── Features/
│   ├── Home/
│   │   ├── HomeViewModel.swift
│   │   ├── HomeViewController.swift
│   │   └── HomeView.swift             UIView: table view + loading indicator
│   └── ItemDetail/
│       ├── ItemDetailViewModel.swift
│       ├── ItemDetailViewController.swift
│       └── ItemDetailContentView.swift
└── Resources/
```

New screens go in `Features/<Feature>/` as `<Feature>ViewModel.swift`,
`<Feature>ViewController.swift` and `<Feature>View.swift`. New flows go in `Coordinators/` as
`<Flow>Coordinator.swift`.

## Responsibilities

| Type | Does | Doesn't |
|---|---|---|
| `HomeViewModel` | Owns `state` (`idle`/`loading`/`loaded`/`failed`), calls `itemService`, exposes `items`, raises `onSelectItem` | Import UIKit, navigate |
| `HomeViewController` | Sets `onStateChange` and calls `render(_:)`, acts as table data source and delegate, forwards taps to `viewModel.selectItem(at:)` | Fetch data, push screens |
| `HomeView` | Builds and lays out subviews; `setLoading(_:)` | Hold state |
| `AppCoordinator` | Builds screens with their dependencies, sets `onSelectItem`, pushes `ItemDetailViewController` | Contain screen logic |
| `ItemService` | Fetches data through `APIClientProtocol` | Know about UI |

## Communication

```
SceneDelegate ──strong──▶ AppCoordinator ──▶ DependencyContainer
                              │ owns UINavigationController
                              │ creates
                              ▼
          HomeViewController ──strong──▶ HomeViewModel ──strong──▶ any ItemServicing
                 ▲                              │
                 └── onStateChange(state) ──────┤  [weak self] in the view controller
                                                └── onSelectItem(item) ──▶ AppCoordinator ([weak self])
```

- **State → view:** `state` has a `didSet` that calls `onStateChange?(state)`. The view controller
  sets the closure in `viewDidLoad` with `[weak self]`, and `render(_:)` updates the UI from the full
  state (loading indicator, `reloadData()`, error alert).
- **Input → view model:** UIKit delegates or target-action in the view controller call view model
  methods, e.g. `viewModel.selectItem(at:)`, or `Task { await viewModel.load() }`.
- **Navigation events → coordinator:** the view model exposes `var onSelectItem: ((Item) -> Void)?`.
  The coordinator sets it with `[weak self]` when it builds the screen.
- **Data forward:** coordinators pass input into the next view model's `init`, e.g.
  `ItemDetailViewModel(item:)`. **Data back:** the child raises an event closure (e.g.
  `onFinish: (Result) -> Void`), and the coordinator handles it and updates the earlier screen's view
  model.

## Routing

```swift
// AppCoordinator
func start() {
    let viewModel = HomeViewModel(itemService: dependencies.itemService)
    viewModel.onSelectItem = { [weak self] item in
        self?.showDetail(of: item)
    }
    navigationController.setViewControllers([HomeViewController(viewModel: viewModel)], animated: false)
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
}

func showDetail(of item: Item) {
    let viewController = ItemDetailViewController(viewModel: ItemDetailViewModel(item: item))
    navigationController.pushViewController(viewController, animated: true)
}
```

- **Root:** `SceneDelegate` creates `AppCoordinator(window:dependencies:)`, calls `start()`, and keeps
  it in `appCoordinator`. Something must hold every coordinator strongly, or it is deallocated.
- **Push within a flow:** add a private `show<Screen>` method to the coordinator.
- **A separate flow** (onboarding, login, a modal wizard): create `<Flow>Coordinator: Coordinator`
  that takes the `UINavigationController` (or a new one to present), and start it with
  `addChild(_:)`. When the flow ends, the child reports back through a closure (`onFinish`), and the
  parent calls `removeChild(_:)` and dismisses it.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`SceneDelegate` passes it to `AppCoordinator`. Coordinators pass specific services into view models,
and child coordinators receive the container in their `init`. View models and view controllers never
see the container.

## Adding a feature

1. Add models to `Domain/Models/`. Add the service to `Domain/Services/` and create it in
   `DependencyContainer`.
2. Create `Features/<Feature>/<Feature>ViewModel.swift`:

   ```swift
   import Foundation

   @MainActor
   final class SettingsViewModel {
       enum State: Equatable {
           case idle
           case loading
           case loaded(Settings)
           case failed(String)
       }

       private(set) var state: State = .idle {
           didSet { onStateChange?(state) }
       }

       var onStateChange: ((State) -> Void)?
       var onClose: (() -> Void)?

       private let settingsService: any SettingsServicing

       init(settingsService: any SettingsServicing) {
           self.settingsService = settingsService
       }
   }
   ```

3. Create `<Feature>View.swift`, a `UIView` built in code, and `<Feature>ViewController.swift`, which
   takes the view model in `init`, sets `view = <feature>View` in `loadView()`, and binds
   `onStateChange` in `viewDidLoad()`.
4. In the coordinator that owns the flow, add `show<Feature>()`. It builds the view model with its
   services, sets its event closures with `[weak self]`, and pushes the view controller. Raise the
   triggering event from the previous view model.
5. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `HomeViewModelTests.swift` is the sample.

- Test **view models**. Create them with `MockItemService` (`Mocks/MockItemService.swift`).
- Record states by setting `onStateChange = { states.append($0) }`, then
  `#expect(states == [.loading, .loaded(Item.samples)])`.
- Test navigation by setting the event closure and asserting on what it received, e.g.
  `viewModel.onSelectItem = { selected = $0 }`, then `#expect(selected == Item.samples[0])`.
- Coordinators can be tested with a real `UINavigationController`, asserting on `viewControllers`
  after calling the action.
- Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** capture `[weak self]` in every closure assigned to a view model, in view controllers and in
  coordinators.
- **Do** render from the whole `State` in one `render(_:)` method instead of mutating the UI
  piecemeal.
- **Don't** call `navigationController?.pushViewController` from a view controller. Raise an event
  and let the coordinator navigate.
- **Don't** import UIKit in view models or pass `UIViewController`s into them.
- **Don't** create `DependencyContainer()` outside `SceneDelegate`.
