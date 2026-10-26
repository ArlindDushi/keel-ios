# Architecture: VIPER (SwiftUI)

{{APP_NAME}} uses VIPER with SwiftUI. Each screen is a **module** split into five parts:

- **View:** renders state and forwards events.
- **Interactor:** business logic and data access.
- **Presenter:** turns entities into display state and handles view events.
- **Entity:** plain models.
- **Router:** builds the screens the module navigates to.

A **module builder** creates and connects the parts. Contracts (protocols) in
`<Module>Contracts.swift` describe how they talk.

Rules:
- The view talks only to its presenter, and it renders only presenter state such as
  `HomeItemViewModel`, never raw entities.
- The presenter never imports SwiftUI. It decides *that* navigation happens by setting state such as
  `selectedItem`; the router decides *what* is shown.
- The interactor is the only part that touches services.
- Modules never build each other directly. A router calls the destination's module builder.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── {{APP_NAME}}App.swift       @main; NavigationStack { HomeModuleBuilder.build(...) }
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Core/
│   ├── Components/ItemRow.swift    Reusable views
│   └── …                           Networking, Environment, DesignSystem, Extensions
├── Entities/
│   └── Item.swift
├── Modules/
│   ├── Home/
│   │   ├── HomeContracts.swift        HomeInteractorProtocol, HomeRouterProtocol, HomeItemViewModel
│   │   ├── HomeView.swift             HomeView<Router: HomeRouterProtocol>
│   │   ├── HomePresenter.swift        @Observable display state + event handlers
│   │   ├── HomeInteractor.swift
│   │   ├── HomeRouter.swift
│   │   └── HomeModuleBuilder.swift
│   └── ItemDetail/                    Display-only: builder + view, no interactor or router
│       ├── ItemDetailModuleBuilder.swift
│       └── ItemDetailView.swift
├── Services/
│   └── ItemService.swift           ItemServicing protocol + ItemService
└── Resources/
```

New modules go in `Modules/<Module>/` and use the same file names. Include only the parts the module
needs: a display-only screen needs just a builder and a view, as `ItemDetail` shows. Entities go in
`Entities/` and services in `Services/`.

## Responsibilities

| Part | Does | Doesn't |
|---|---|---|
| `HomeView` | Renders `presenter.items` / `isLoading` / `errorMessage`; calls `presenter.onAppear()`, `loadItems()`, `didSelect(_:)`; binds `navigationDestination(item: $presenter.selectedItem)` to `router.detail(of:)` | Hold logic, call the interactor |
| `HomePresenter` | Calls the interactor, maps `Item` to `HomeItemViewModel`, keeps the entities privately, sets `selectedItem` | Import SwiftUI, build views |
| `HomeInteractor` (`HomeInteractorProtocol`) | Business rules and service calls (`itemService.fetchItems()`) | Format data for display |
| `HomeRouter` (`HomeRouterProtocol`) | `detail(of:)` returns `ItemDetailModuleBuilder.build(item:)` | Hold state |
| `HomeModuleBuilder` | `build(dependencies:)` wires the interactor, presenter, router and view | Contain logic |
| `Item` (Entity) | Plain data | Know about any module |

## Communication

```
HomeModuleBuilder.build(dependencies:)
   └─▶ HomeView<HomeRouter>
          ├─ @State ─▶ HomePresenter ── strong ─▶ any HomeInteractorProtocol ─▶ any ItemServicing
          └─ let ────▶ HomeRouter ── detail(of:) ─▶ ItemDetailModuleBuilder.build(item:)
```

- **View → presenter:** method calls (`onAppear()`, `didSelect(_:)`) started from `.task` or a
  button `Task`.
- **Presenter → interactor:** `try await interactor.fetchItems()`. The interactor returns entities or
  throws.
- **Presenter → view:** the presenter is `@MainActor @Observable`, so the view re-renders when
  `items`, `isLoading` or `errorMessage` change. Display models (`HomeItemViewModel`) are declared
  in the contracts file.
- **Navigation:** the presenter sets `selectedItem`. The view's `navigationDestination(item:)` asks
  the router for the destination view.
- **Data back from a child module:** pass a closure into the child's builder, e.g.
  `build(item:onSave:)`. The router forwards it from a presenter method, and the child's presenter
  calls it.

## Routing

```swift
// HomeContracts.swift
@MainActor
protocol HomeRouterProtocol {
    associatedtype Detail: View
    func detail(of item: Item) -> Detail
}

// HomeRouter.swift
struct HomeRouter: HomeRouterProtocol {
    func detail(of item: Item) -> some View {
        ItemDetailModuleBuilder.build(item: item)
    }
}

// HomeView.swift
.navigationDestination(item: $presenter.selectedItem) { item in
    router.detail(of: item)
}
```

- **Root:** `{{APP_NAME}}App` wraps `HomeModuleBuilder.build(dependencies:)` in one
  `NavigationStack`. Modules must not add another `NavigationStack`, except a module presented as a
  sheet that needs its own bar.
- **Each destination** gets an `associatedtype` and a method on the router protocol, plus an optional
  property on the presenter (`selectedItem`, `presentedSettings`…). The view binds it with
  `navigationDestination(item:)`, `.sheet(item:)` or `.fullScreenCover(item:)`.
- `HomeView` is generic over its router (`HomeView<Router: HomeRouterProtocol>`), so the router can
  return `some View` without type erasure. Previews and tests can supply another router.
- If the destination module needs services, give the router the dependencies it needs (e.g.
  `HomeRouter(dependencies:)`), and have it call the destination's builder with them.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`{{APP_NAME}}App` owns it and passes it to the root module builder. Each builder hands the specific
services to its interactor, and to its router when other modules need them. Presenters and views
never see services or the container.

## Adding a module

1. Add entities to `Entities/`. Add the service to `Services/` and create it in
   `DependencyContainer`.
2. `Modules/<Module>/<Module>Contracts.swift`: declare `<Module>InteractorProtocol: Sendable`, the
   `@MainActor` router protocol with one method per destination, and the display models.
3. `<Module>Interactor.swift`: a struct that takes the services and implements the interactor
   protocol.
4. `<Module>Presenter.swift`:

   ```swift
   @MainActor
   @Observable
   final class SettingsPresenter {
       private(set) var rows: [SettingsRowViewModel] = []
       private(set) var errorMessage: String?
       var selectedOption: SettingsOption?

       private let interactor: any SettingsInteractorProtocol

       init(interactor: any SettingsInteractorProtocol) {
           self.interactor = interactor
       }
   }
   ```

5. `<Module>Router.swift`: a struct that implements the router protocol by calling other modules'
   builders.
6. `<Module>View.swift`: `struct <Module>View<Router: <Module>RouterProtocol>: View`. It holds the
   presenter in `@State`, binds navigation to the presenter's optional state, and has a `#Preview`.
7. `<Module>ModuleBuilder.swift`: an `@MainActor enum` with
   `static func build(dependencies:) -> some View`.
8. To open the module from another one, add a method to that module's router protocol and router,
   plus a presenter property to drive it.
9. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `HomePresenterTests.swift` is the sample.

- **Presenters:** create them with a real interactor over `MockItemService`
  (`Mocks/MockItemService.swift`), or with a stub that conforms to `HomeInteractorProtocol`.
  `await presenter.loadItems()`, then assert on `items`, `isLoading` and `errorMessage`.
- **Navigation:** call `presenter.didSelect(_:)` and assert that `selectedItem` is set.
- **Interactors:** test the business rules with a mocked service.
- Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** keep every module's protocols in its `Contracts` file.
- **Do** map entities to display models in the presenter, so the view never formats data.
- **Don't** call services from the presenter or the view. Go through the interactor.
- **Don't** build another module's view inside a view. Ask the router.
- **Don't** add parts a module doesn't need. A display-only screen is a builder plus a view.
