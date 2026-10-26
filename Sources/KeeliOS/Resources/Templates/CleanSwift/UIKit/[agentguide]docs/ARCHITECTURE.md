# Architecture: Clean Swift / VIP (UIKit)

{{APP_NAME}} uses Clean Swift: Clean Architecture arranged as a one-way **VIP cycle** for each
**scene**:

```
ViewController ──Request──▶ Interactor ──Response──▶ Presenter ──ViewModel──▶ ViewController
```

Each use case in a scene has its own `Request`, `Response` and `ViewModel` types in
`<Scene>Models.swift`. Data moves around the cycle in one direction only.

Rules:
- The view controller sends **Requests** to the interactor (`HomeBusinessLogic`) and implements the
  display protocol (`HomeDisplayLogic`). It never calls the presenter or services.
- The interactor holds the business logic. It delegates service work to a **worker** and sends
  **Responses** to the presenter. It never formats data for display.
- The presenter turns Responses into **ViewModels** and sends them to the view controller. It never
  imports UIKit.
- The **router** (`HomeRoutingLogic` + `HomeDataPassing`) reads what the next scene needs from the
  interactor's **data store** and navigates.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── AppDelegate.swift           Launch; calls ThirdPartyServices.configure()
│   ├── SceneDelegate.swift         Root UINavigationController around HomeConfigurator.configure(...)
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Core/                           Networking, Environment, DesignSystem, Extensions
├── Models/
│   └── Item.swift                  App-wide entities
├── Scenes/
│   ├── Home/
│   │   ├── HomeModels.swift          enum Home { FetchItems, SelectItem } with Request/Response/ViewModel
│   │   ├── HomeViewController.swift  HomeDisplayLogic + the view controller
│   │   ├── HomeView.swift            UIView: table view + loading indicator
│   │   ├── HomeInteractor.swift      HomeBusinessLogic + HomeDataStore
│   │   ├── HomePresenter.swift       HomePresentationLogic
│   │   ├── HomeWorker.swift          Service calls for the interactor
│   │   ├── HomeRouter.swift          HomeRoutingLogic + HomeDataPassing
│   │   └── HomeConfigurator.swift    Wires the cycle
│   └── ItemDetail/                   Display-only: configurator + view controller
│       ├── ItemDetailConfigurator.swift
│       ├── ItemDetailViewController.swift
│       └── ItemDetailContentView.swift
├── Services/
│   └── ItemService.swift           ItemServicing protocol + ItemService
└── Resources/
```

New scenes go in `Scenes/<Scene>/` and use the same file names. Include only what the scene needs:
a display-only scene is a configurator plus a view controller, as `ItemDetail` shows.

## Protocols and responsibilities

| Type | Protocol(s) | Does |
|---|---|---|
| `HomeViewController` | `HomeDisplayLogic` | Sends `interactor?.fetchItems(request:)` and `selectItem(request:)`; implements `displayItems`, `displayError` and `displaySelectedItem` (which calls `router?.routeToItemDetail()`) |
| `HomeView` | — | Builds and lays out subviews; `setLoading(_:)` |
| `HomeInteractor` | `HomeBusinessLogic`, `HomeDataStore` | Runs use cases through the worker, stores `selectedItem`, calls `presenter?.present…(response:)` |
| `HomeWorker` | — (`Sendable` struct) | Calls services |
| `HomePresenter` | `HomePresentationLogic` | Maps Responses to ViewModels, calls `display?.display…(viewModel:)` |
| `HomeRouter` | `HomeRoutingLogic`, `HomeDataPassing` | `routeToItemDetail()` reads `dataStore?.selectedItem` and pushes `ItemDetailConfigurator.configure(item:)` |
| `HomeConfigurator` | — | `configure(dependencies:) -> UIViewController` creates and connects everything |

## Communication

```
HomeViewController ──strong interactor──▶ HomeInteractor ──strong presenter──▶ HomePresenter
        ▲          ──strong router──────▶ HomeRouter            │ strong worker            │
        │                                   │  │ strong dataStore ─▶ (HomeInteractor)       │
        │                                   │  └ weak viewController ─▶ HomeViewController │
        └──────────────────────────── weak display ────────────────────────────────────────┘
```

One use case, end to end:
1. `HomeViewController` → `interactor?.fetchItems(request: Home.FetchItems.Request())` in a `Task`.
2. `HomeInteractor` → `worker.fetchItems()` → `presenter?.presentItems(response: Home.FetchItems.Response(result:))`.
3. `HomePresenter` → `display?.displayItems(viewModel:)` or `displayError(viewModel:)`.
4. `HomeViewController` stores `displayedItems` and reloads the table.

- The view controller owns the interactor and the router. The presenter's `display` and the
  router's `viewController` are `weak`, which keeps the cycle free of retain cycles.
- `HomeViewController` has no init parameters. The configurator sets `interactor` and `router` as
  properties after creating it.
- **Data back from a child scene:** pass a closure into the child's configurator. The child's
  interactor calls it, and it sends a Request to the parent's interactor.

## Routing

```swift
// HomeRouter.swift
@MainActor
final class HomeRouter: HomeRoutingLogic, HomeDataPassing {
    weak var viewController: UIViewController?
    var dataStore: (any HomeDataStore)?

    func routeToItemDetail() {
        guard let item = dataStore?.selectedItem else { return }
        viewController?.navigationController?.pushViewController(ItemDetailConfigurator.configure(item: item), animated: true)
    }
}
```

- **Root:** `SceneDelegate` sets
  `UINavigationController(rootViewController: HomeConfigurator.configure(dependencies:))`.
- Navigation is a use case too:
  1. A row tap sends `selectItem(request:)`.
  2. The interactor stores `selectedItem` in its data store and presents a Response.
  3. The presenter calls `displaySelectedItem(viewModel:)`.
  4. The view controller calls `router?.routeToItemDetail()`.
- Each destination is a `routeTo<Scene>()` method on `<Scene>RoutingLogic`. It reads its input from
  `dataStore` and builds the destination with its configurator. If the destination needs services,
  give the router the dependencies and pass them to its configurator.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`SceneDelegate` owns it and passes it to the root configurator. Each configurator gives the specific
services to its worker, and to its router when other scenes need them. Interactors, presenters and
view controllers never see the container.

## Adding a scene or use case

**A new use case in an existing scene:**
1. Add `enum <UseCase> { struct Request; struct Response; struct ViewModel }` to `<Scene>Models.swift`.
2. Add `func <useCase>(request:)` to `<Scene>BusinessLogic` and implement it in the interactor.
3. Add `present<UseCase>(response:)` to `<Scene>PresentationLogic` and implement it in the presenter.
4. Add `display<UseCase>(viewModel:)` to `<Scene>DisplayLogic` and implement it in the view
   controller.
5. Send the Request from the view controller.

**A new scene:**
1. Create `Scenes/<Scene>/` with `<Scene>Models.swift`, `<Scene>Worker.swift`,
   `<Scene>Interactor.swift` (`<Scene>BusinessLogic` + `<Scene>DataStore`),
   `<Scene>Presenter.swift` (`<Scene>PresentationLogic`, `weak var display`),
   `<Scene>ViewController.swift` (`<Scene>DisplayLogic`), `<Scene>View.swift` and `<Scene>Router.swift`
   (`<Scene>RoutingLogic` + `<Scene>DataPassing`). All of the protocols are `@MainActor` and
   `AnyObject`.
2. `<Scene>Configurator.swift`:

   ```swift
   @MainActor
   enum SettingsConfigurator {
       static func configure(dependencies: DependencyContainer) -> UIViewController {
           let viewController = SettingsViewController()
           let interactor = SettingsInteractor(worker: SettingsWorker(settingsService: dependencies.settingsService))
           let presenter = SettingsPresenter()
           let router = SettingsRouter()

           viewController.interactor = interactor
           viewController.router = router
           interactor.presenter = presenter
           presenter.display = viewController
           router.viewController = viewController
           router.dataStore = interactor
           return viewController
       }
   }
   ```

3. Open it from another scene by adding a `routeTo<Scene>()` method to that scene's router.
4. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `HomeInteractorTests.swift` and `HomePresenterTests.swift` are the
samples. Each part of the cycle is tested on its own:

- **Interactor:** a `PresenterSpy: HomePresentationLogic` records Responses. The worker runs over
  `MockItemService` (`Mocks/MockItemService.swift`). Assert on the Response and on the data store
  (`selectedItem`).
- **Presenter:** a `DisplaySpy: HomeDisplayLogic` records ViewModels. Call `present…(response:)`
  with a fixed Response, then assert on the ViewModel.
- **Router:** set a `dataStore` stub and a `viewController` inside a `UINavigationController`, call
  `routeTo…()`, then assert on `viewControllers`.
- Keep spies `private final class` inside the test struct. Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** give every use case its own Request, Response and ViewModel, even when one is empty.
- **Do** keep `display` and `viewController` references `weak`.
- **Don't** push from the view controller. Call the router from a `display…` method.
- **Don't** call services from the interactor directly. Add a worker method.
- **Don't** put display formatting in the interactor, or business rules in the presenter.
