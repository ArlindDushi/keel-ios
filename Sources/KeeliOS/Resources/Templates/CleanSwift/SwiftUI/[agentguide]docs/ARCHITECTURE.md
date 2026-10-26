# Architecture: Clean Swift / VIP (SwiftUI)

{{APP_NAME}} uses Clean Swift: Clean Architecture arranged as a one-way **VIP cycle** for each
**scene**:

```
View ──Request──▶ Interactor ──Response──▶ Presenter ──ViewModel──▶ View state ──▶ View
```

Each use case in a scene has its own `Request`, `Response` and `ViewModel` types in
`<Scene>Models.swift`. Data moves around the cycle in one direction only.

Rules:
- The view sends **Requests** to the interactor (`HomeBusinessLogic`) and never calls the presenter
  or services.
- The interactor holds the business logic. It delegates service work to a **worker** and sends
  **Responses** to the presenter. It never formats data for display.
- The presenter turns Responses into **ViewModels** (display-ready strings and values) and sends them
  to the display (`HomeDisplayLogic`). It never imports SwiftUI.
- In SwiftUI, the display is an `@Observable` **view state** class (`HomeViewState`). The view
  renders it.
- The **router** reads what the next scene needs from the interactor's **data store** and builds that
  scene.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── {{APP_NAME}}App.swift       @main; NavigationStack { HomeConfigurator.configure(...) }
│   ├── DependencyContainer.swift   Creates shared services once
│   └── ThirdPartyServices.swift
├── Core/
│   ├── Components/ItemRow.swift    Reusable views
│   └── …                           Networking, Environment, DesignSystem, Extensions
├── Models/
│   └── Item.swift                  App-wide entities
├── Scenes/
│   ├── Home/
│   │   ├── HomeModels.swift        enum Home { FetchItems, SelectItem } with Request/Response/ViewModel
│   │   ├── HomeView.swift          Renders HomeViewState, sends Requests
│   │   ├── HomeViewState.swift     HomeDisplayLogic + @Observable display state
│   │   ├── HomeInteractor.swift    HomeBusinessLogic + HomeDataStore
│   │   ├── HomePresenter.swift     HomePresentationLogic
│   │   ├── HomeWorker.swift        Service calls for the interactor
│   │   ├── HomeRouter.swift        Builds destination scenes from the data store
│   │   └── HomeConfigurator.swift  Wires the cycle
│   └── ItemDetail/                 Display-only: configurator + view
│       ├── ItemDetailConfigurator.swift
│       └── ItemDetailView.swift
├── Services/
│   └── ItemService.swift           ItemServicing protocol + ItemService
└── Resources/
```

New scenes go in `Scenes/<Scene>/` and use the same file names. Include only what the scene needs:
a display-only scene is a configurator plus a view, as `ItemDetail` shows.

## Protocols and responsibilities

| Type | Protocol(s) | Does |
|---|---|---|
| `HomeView` | — | Renders `HomeViewState`; calls `interactor.fetchItems(request:)` and `selectItem(request:)`; binds `navigationDestination(isPresented: $state.isShowingItemDetail)` to `router.itemDetail()` |
| `HomeInteractor` | `HomeBusinessLogic`, `HomeDataStore` | Runs use cases through the worker, stores state the router needs (`selectedItem`), calls `presenter?.present…(response:)` |
| `HomeWorker` | — (`Sendable` struct) | Calls services (`itemService.fetchItems()`) |
| `HomePresenter` | `HomePresentationLogic` | Maps Responses to ViewModels, calls `display?.display…(viewModel:)` |
| `HomeViewState` | `HomeDisplayLogic` | Stores `displayedItems`, `isLoading`, `errorMessage`, `isShowingItemDetail` for the view |
| `HomeRouter` | — | `itemDetail()` builds `ItemDetailConfigurator.configure(item:)` from `dataStore.selectedItem` |
| `HomeConfigurator` | — | `configure(dependencies:)` creates and connects everything |

## Communication

```
HomeView ──@State──▶ HomeViewState      (renders)
    │    ──@State──▶ any HomeBusinessLogic (HomeInteractor) ──strong──▶ HomeWorker ─▶ any ItemServicing
    │    ──@State──▶ HomeRouter ──▶ any HomeDataStore (same HomeInteractor)
    │
    └─ Request ─▶ HomeInteractor ── strong presenter ─▶ HomePresenter ── weak display ─▶ HomeViewState
```

One use case, end to end:
1. `HomeView` → `interactor.fetchItems(request: Home.FetchItems.Request())`.
2. `HomeInteractor` → `worker.fetchItems()` → `presenter?.presentItems(response: Home.FetchItems.Response(result:))`.
3. `HomePresenter` → `display?.displayItems(viewModel: Home.FetchItems.ViewModel(displayedItems:))`
   or `displayError(viewModel:)`.
4. `HomeViewState` updates `displayedItems`, and `HomeView` re-renders.

- Every use case has its own namespace in `<Scene>Models.swift`
  (`enum Home { enum FetchItems { struct Request; struct Response; struct ViewModel } }`).
- The presenter's `display` reference is `weak`. The view's `@State` keeps the cycle alive.
- **Data back from a child scene:** pass a closure into the child's configurator. The child's
  interactor calls it, and it sends a Request to the parent's interactor.

## Routing

```swift
// HomeInteractor (data store)
func selectItem(request: Home.SelectItem.Request) {
    let item = items[request.index]
    selectedItem = item
    presenter?.presentSelectedItem(response: Home.SelectItem.Response(item: item))
}

// HomeViewState (display logic)
func displaySelectedItem(viewModel: Home.SelectItem.ViewModel) {
    isShowingItemDetail = true
}

// HomeView
.navigationDestination(isPresented: $state.isShowingItemDetail) {
    router.itemDetail()
}

// HomeRouter
@ViewBuilder
func itemDetail() -> some View {
    if let item = dataStore.selectedItem {
        ItemDetailConfigurator.configure(item: item)
    }
}
```

- **Root:** `{{APP_NAME}}App` wraps `HomeConfigurator.configure(dependencies:)` in one
  `NavigationStack`. Scenes don't add another one.
- Navigation is a use case too. A Request goes to the interactor, which stores the data the next
  scene needs in the data store. The presenter and display then flip a flag
  (`isShowingItemDetail`). The view binds the flag to `navigationDestination(isPresented:)`,
  `.sheet(isPresented:)` and so on, and asks the router for the destination.
- Each destination is a method on `<Scene>Router`, reading from `<Scene>DataStore`. If the
  destination needs services, give the router the dependencies and pass them to its configurator.

## Dependency injection

`DependencyContainer` (`App/DependencyContainer.swift`) creates `APIClient` and every service.
`{{APP_NAME}}App` passes it to the root configurator. Each configurator gives the specific services
to its worker, and to its router when other scenes need them. Interactors, presenters and views
never see the container.

## Adding a scene or use case

**A new use case in an existing scene:**
1. Add `enum <UseCase> { struct Request; struct Response; struct ViewModel }` to `<Scene>Models.swift`.
2. Add `func <useCase>(request:)` to `<Scene>BusinessLogic` and implement it in the interactor.
3. Add `present<UseCase>(response:)` to `<Scene>PresentationLogic` and implement it in the presenter.
4. Add `display<UseCase>(viewModel:)` to `<Scene>DisplayLogic` and implement it in the view state.
5. Send the Request from the view.

**A new scene:**
1. Create `Scenes/<Scene>/` with `<Scene>Models.swift`, `<Scene>Worker.swift` (a `Sendable` struct
   over services), `<Scene>Interactor.swift` (`<Scene>BusinessLogic` + `<Scene>DataStore`),
   `<Scene>Presenter.swift`, `<Scene>ViewState.swift`, `<Scene>View.swift` and
   `<Scene>Router.swift`. All of the protocols are `@MainActor` and `AnyObject`.
2. `<Scene>Configurator.swift`:

   ```swift
   @MainActor
   enum SettingsConfigurator {
       static func configure(dependencies: DependencyContainer) -> some View {
           let state = SettingsViewState()
           let interactor = SettingsInteractor(worker: SettingsWorker(settingsService: dependencies.settingsService))
           let presenter = SettingsPresenter()
           interactor.presenter = presenter
           presenter.display = state
           return SettingsView(state: state, interactor: interactor, router: SettingsRouter(dataStore: interactor))
       }
   }
   ```

3. Open it from another scene by adding a method to that scene's router, plus a flag in its view
   state set by a `display…` method.
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
- **View state:** call `display…(viewModel:)`, then assert on its properties.
- Keep spies `private final class` inside the test struct. Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** give every use case its own Request, Response and ViewModel, even when one is empty.
- **Do** keep the cycle one-way: the view never reads the presenter, and the presenter never calls
  the interactor.
- **Don't** call services from the interactor directly. Add a worker method.
- **Don't** put display formatting in the interactor, or business rules in the presenter.
- **Don't** pass entities to the view. The presenter maps them to ViewModels.
