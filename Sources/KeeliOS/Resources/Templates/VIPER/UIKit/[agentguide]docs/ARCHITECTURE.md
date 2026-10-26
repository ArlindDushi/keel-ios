# Architecture: VIPER (UIKit)

{{APP_NAME}} uses VIPER with UIKit. Each screen is a **module** split into five parts:

- **View** (a view controller): displays what it's told and forwards events.
- **Interactor:** business logic and data access.
- **Presenter:** coordinates the module and formats data for the view.
- **Entity:** plain models.
- **Router:** navigation away from the module.

A **module builder** creates and connects the parts. Every connection goes through a protocol in
`<Module>Contracts.swift`.

Rules:
- Parts know each other only through the contract protocols, never through concrete types (the
  builder is the exception).
- The view is passive. It calls the presenter on events and implements `display…` methods.
- The presenter has no UIKit imports. It turns entities into display models (`HomeItemViewModel`)
  and asks the router to navigate.
- The interactor is the only part that touches services. The router is the only part that pushes or
  presents.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── AppDelegate.swift           Launch; calls ThirdPartyServices.configure()
│   ├── SceneDelegate.swift         Root UINavigationController around HomeModuleBuilder.build(...)
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Core/                           Networking, Environment, DesignSystem, Extensions
├── Entities/
│   └── Item.swift
├── Modules/
│   ├── Home/
│   │   ├── HomeContracts.swift        View/Presenter/Interactor/Router protocols + HomeItemViewModel
│   │   ├── HomeViewController.swift   Implements HomeViewProtocol
│   │   ├── HomeView.swift             UIView: table view + loading indicator
│   │   ├── HomePresenter.swift
│   │   ├── HomeInteractor.swift
│   │   ├── HomeRouter.swift
│   │   └── HomeModuleBuilder.swift
│   └── ItemDetail/                    Display-only: builder + view controller, no interactor or router
│       ├── ItemDetailModuleBuilder.swift
│       ├── ItemDetailViewController.swift
│       └── ItemDetailContentView.swift
├── Services/
│   └── ItemService.swift           ItemServicing protocol + ItemService
└── Resources/
```

New modules go in `Modules/<Module>/` and use the same file names. Include only the parts the module
needs. Entities go in `Entities/` and services in `Services/`.

## Responsibilities and contracts

| Part | Protocol (in `HomeContracts.swift`) | Does |
|---|---|---|
| `HomeViewController` | `HomeViewProtocol`: `display(_:)`, `displayLoading(_:)`, `displayError(_:)` | Shows what it's given; calls `presenter.viewDidLoad()`, `didSelectItem(at:)`, `didTapRetry()` |
| `HomePresenter` | `HomePresenterProtocol`: `viewDidLoad()`, `didSelectItem(at:)`, `didTapRetry()` | Calls the interactor, maps `Item` to `HomeItemViewModel`, updates the view, calls the router |
| `HomeInteractor` | `HomeInteractorProtocol: Sendable`: `fetchItems()` | Business rules and service calls |
| `HomeRouter` | `HomeRouterProtocol`: `showDetail(of:)` | Builds the next module and pushes it |
| `HomeModuleBuilder` | — | `build(dependencies:) -> UIViewController` wires everything |

## Communication

```
                    strong                       strong
HomeViewController ───────▶ HomePresenter ───────────────▶ any HomeInteractorProtocol ─▶ any ItemServicing
        ▲                       │      │ strong
        └──── weak view ────────┘      └──────────▶ any HomeRouterProtocol
                                                         │
UIViewController ◀──────────── weak viewController ──────┘
```

- **Ownership:** the view controller owns the presenter. The presenter owns the interactor and the
  router. The presenter's `view` and the router's `viewController` are `weak`, which keeps the
  module free of retain cycles. Keep it that way in every module.
- **View → presenter:** event methods only (`viewDidLoad()`, `didSelectItem(at:)`, `didTapRetry()`),
  named after what happened, not what should happen.
- **Presenter → interactor:** `try await interactor.fetchItems()` inside `Task { await loadItems() }`.
- **Presenter → view:** `view?.display(...)`, `view?.displayLoading(...)`, `view?.displayError(...)`.
  These take display models, never entities.
- **Presenter → router:** `router.showDetail(of: item)`.
- **Data back from a child module:** pass a closure or a `weak` delegate protocol into the child's
  builder, e.g. `build(item:onSave:)`. The child's presenter calls it, and the parent's presenter
  handles it.

## Routing

```swift
// HomeRouter.swift
@MainActor
final class HomeRouter: HomeRouterProtocol {
    weak var viewController: UIViewController?

    func showDetail(of item: Item) {
        viewController?.navigationController?.pushViewController(ItemDetailModuleBuilder.build(item: item), animated: true)
    }
}

// HomeModuleBuilder.swift
let router = HomeRouter()
let presenter = HomePresenter(interactor: HomeInteractor(itemService: dependencies.itemService), router: router)
let viewController = HomeViewController(presenter: presenter)
presenter.view = viewController
router.viewController = viewController
```

- **Root:** `SceneDelegate` sets
  `UINavigationController(rootViewController: HomeModuleBuilder.build(dependencies:))`.
- **Every** destination is a method on the router protocol (`showSettings()`,
  `presentLogin()`…). The router builds the destination with its module builder, then pushes,
  presents or dismisses through `viewController`.
- If the destination needs services, give the router the dependencies (e.g.
  `HomeRouter(dependencies:)`), and have it pass them to the destination's builder.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`SceneDelegate` owns it and passes it to the root module builder. Builders hand services to their
interactor, and to their router when other modules need them. Presenters, views and interactors
never see the container.

## Adding a module

1. Add entities to `Entities/`. Add the service to `Services/` and create it in
   `DependencyContainer`.
2. `Modules/<Module>/<Module>Contracts.swift`: the four protocols, following `HomeContracts.swift`.
   The view, presenter and router protocols are `@MainActor` and `AnyObject`; the interactor protocol
   is `Sendable`. Add the display models here too.
3. `<Module>Interactor.swift`: a struct over the services.
4. `<Module>Presenter.swift`:

   ```swift
   @MainActor
   final class SettingsPresenter: SettingsPresenterProtocol {
       weak var view: (any SettingsViewProtocol)?
       private let interactor: any SettingsInteractorProtocol
       private let router: any SettingsRouterProtocol

       init(interactor: any SettingsInteractorProtocol, router: any SettingsRouterProtocol) {
           self.interactor = interactor
           self.router = router
       }
   }
   ```

5. `<Module>Router.swift`: `final class` with `weak var viewController: UIViewController?`.
6. `<Module>ViewController.swift` and `<Module>View.swift`: the view controller takes the presenter
   in `init`, sets `view = <module>View` in `loadView()`, and implements the view protocol.
7. `<Module>ModuleBuilder.swift`: wire everything, set `presenter.view` and
   `router.viewController`, and return the view controller.
8. Open it from another module by adding a method to that module's router protocol and router.
9. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `HomePresenterTests.swift` is the sample.

- **Presenters:** use a `ViewSpy` that conforms to the view protocol and records `display…` calls,
  and a `RouterSpy` that conforms to the router protocol and records navigation. Build the
  interactor over `MockItemService` (`Mocks/MockItemService.swift`).
- `await presenter.loadItems()`, then assert on the spy (`view.displayedItems`, `view.errorMessage`).
  For navigation, call `presenter.didSelectItem(at:)` and assert `router.shownItem`.
- **Interactors:** test the business rules with a mocked service.
- Keep spies `private final class` inside the test struct. Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** keep `view` and `viewController` references `weak`. Everything else in a module is owned
  through the view controller.
- **Do** depend on the contract protocols (`any HomeRouterProtocol`), so tests can use spies.
- **Don't** push from a view controller or from the presenter. Only the router navigates.
- **Don't** pass entities to the view. Map them to display models in the presenter.
- **Don't** import UIKit in presenters or interactors.
