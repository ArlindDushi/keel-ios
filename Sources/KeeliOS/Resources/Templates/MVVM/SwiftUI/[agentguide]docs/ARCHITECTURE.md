# Architecture: MVVM with a NavigationStack router (SwiftUI)

{{APP_NAME}} uses Model-View-ViewModel with SwiftUI. Each screen has a **view**, which renders state
and forwards user actions, and a **view model**, which owns the state and the logic. Navigation goes
through a shared **`Router`**, so screens never build or reference each other.

Rules:
- Views read the view model's state and call its methods. They never call services, and they never
  push other views directly.
- View models are `@MainActor @Observable final class`es. They get services and the `Router` through
  `init` and import only `Foundation` and `Observation`, never `SwiftUI`.
- Navigation happens only by pushing a `Route` onto the `Router`. Only `RootView` turns a `Route`
  into a view.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── {{APP_NAME}}App.swift       @main; owns DependencyContainer, shows RootView
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Core/
│   ├── Components/ItemRow.swift    Reusable views with no view model
│   └── …                           Networking, Environment, DesignSystem, Extensions
├── Domain/
│   ├── Models/Item.swift
│   └── Services/ItemService.swift  ItemServicing protocol + ItemService
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   └── ItemDetail/
│       ├── ItemDetailView.swift
│       └── ItemDetailViewModel.swift
├── Navigation/
│   ├── Route.swift                 enum Route: every pushable screen
│   ├── Router.swift                Owns the navigation path
│   └── RootView.swift              NavigationStack + Route → View mapping
└── Resources/
```

New screens go in `Features/<Feature>/` as `<Feature>View.swift` and `<Feature>ViewModel.swift`.
Shared views go in `Core/Components/`, models in `Domain/Models/` and services in `Domain/Services/`.

## Responsibilities

| Type | Does | Doesn't |
|---|---|---|
| `HomeView` | Renders `viewModel.state`, calls `viewModel.loadIfNeeded()` in `.task` and `viewModel.select(_:)` on tap | Fetch data, decide where to navigate |
| `HomeViewModel` | Owns `state` (`idle`/`loading`/`loaded`/`failed`), calls `itemService`, tells the router where to go | Import SwiftUI or create views |
| `Router` | Holds `path: [Route]`; `push(_:)`, `pop()`, `popToRoot()` | Know about view models or views |
| `Route` | `Hashable` enum of destinations with their input (`.itemDetail(Item)`) | Hold services |
| `RootView` | Owns the `Router`, hosts `NavigationStack(path:)`, builds each destination's view and view model | Contain feature logic |
| `ItemService` | Fetches data through `APIClientProtocol` | Know about UI |

## Communication

```
{{APP_NAME}}App ──owns──▶ DependencyContainer
      │
      └─▶ RootView(dependencies:) ──@State──▶ Router
              │
              └─ NavigationStack(path: $router.path)
                    └─ HomeView ──@State──▶ HomeViewModel
                                              ├─ strong ─▶ any ItemServicing
                                              └─ strong ─▶ Router (shared instance)
```

- **State flows down.** The view model exposes `private(set) var state`. Because the class is
  `@Observable`, SwiftUI re-renders whatever reads it. Model a screen's state as one `enum State:
  Equatable` rather than several booleans.
- **Actions flow up.** The view calls methods on the view model: `select(_:)`, or `load()` from a
  `Task`.
- **Async work** is an `async` method on the view model, started by the view with
  `.task { await viewModel.loadIfNeeded() }` or `Task { await viewModel.load() }`. Use
  `loadIfNeeded()` so the data doesn't reload every time the view appears.
- The view keeps its view model in `@State`, set once in `init` with
  `_viewModel = State(initialValue: viewModel)`.
- **Passing data back** (for example, a picker): give the child view model a closure such as
  `onPick: (Value) -> Void`, set by the parent's view model when it builds the route. Or move the
  shared state into a service both view models receive.

## Routing

```swift
// Navigation/Route.swift
enum Route: Hashable {
    case itemDetail(Item)
}

// HomeViewModel
func select(_ item: Item) {
    router.push(.itemDetail(item))
}

// Navigation/RootView.swift
NavigationStack(path: $router.path) {
    HomeView(viewModel: HomeViewModel(itemService: dependencies.itemService, router: router))
        .navigationDestination(for: Route.self, destination: destination)
}

@ViewBuilder
func destination(for route: Route) -> some View {
    switch route {
    case let .itemDetail(item):
        ItemDetailView(viewModel: ItemDetailViewModel(item: item))
    }
}
```

- **Root:** `{{APP_NAME}}App` shows `RootView(dependencies:)` in its `WindowGroup`.
- **Push:** `router.push(.someRoute(input))`. **Back:** `router.pop()` or `router.popToRoot()`.
- **Every** pushable screen is a `Route` case, and `RootView.destination(for:)` builds it, injecting
  its services from `dependencies` and passing `router` when the screen navigates further.
- **Sheets and full-screen covers** that belong to one screen can be driven by an optional or a
  `Bool` on that screen's view model, e.g. `var presentedSheet: Sheet?` with `.sheet(item:)`. For
  app-wide modals, add `var sheet: Route?` to `Router` and present it from `RootView`.
- Route cases must be `Hashable`. Pass IDs or small `Hashable` models, never services or view
  models.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`{{APP_NAME}}App` owns it and hands it to `RootView`, which passes the services each view model needs
into its `init`. View models depend on protocols (`any ItemServicing`), never on concrete services
or the container.

## Adding a feature

1. Add models to `Domain/Models/`. Add the service to `Domain/Services/` (a `Sendable` protocol and a
   struct), and create it in `DependencyContainer`.
2. Create `Features/<Feature>/<Feature>ViewModel.swift`:

   ```swift
   import Foundation
   import Observation

   @MainActor
   @Observable
   final class SettingsViewModel {
       enum State: Equatable {
           case idle
           case loading
           case loaded(Settings)
           case failed(String)
       }

       private(set) var state: State = .idle
       private let settingsService: any SettingsServicing
       private let router: Router

       init(settingsService: any SettingsServicing, router: Router) {
           self.settingsService = settingsService
           self.router = router
       }
   }
   ```

3. Create `Features/<Feature>/<Feature>View.swift` with `@State private var viewModel`, an `init`
   that takes the view model, and a `#Preview`.
4. Add a case to `Route` (e.g. `case settings`), and build the screen in
   `RootView.destination(for:)`.
5. Navigate to it from another view model with `router.push(.settings)`.
6. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `HomeViewModelTests.swift` is the sample.

- Test **view models**, not views. Create them with `MockItemService` (`Mocks/MockItemService.swift`)
  and a real `Router()`.
- `await viewModel.load()`, then `#expect(viewModel.state == .loaded(...))`. For failures, use
  `MockItemService(result: .failure(APIError.invalidResponse))`.
- For navigation, call the action and assert on `router.path`, e.g.
  `#expect(router.path == [.itemDetail(Item.samples[0])])`.
- Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** keep one `enum State` per screen, so the view handles every case with a `switch`.
- **Do** inject the shared `Router`. Never create a new `Router()` inside a feature.
- **Don't** put `NavigationLink(destination:)` or `navigationDestination` in feature views. Add a
  `Route` instead.
- **Don't** import SwiftUI in view models or pass `Binding`s into them.
- **Don't** reach `DependencyContainer` from a view model. Pass in only the services it needs.
