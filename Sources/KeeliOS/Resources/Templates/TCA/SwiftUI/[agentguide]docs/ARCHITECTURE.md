# Architecture: The Composable Architecture (SwiftUI)

{{APP_NAME}} uses Point-Free's [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
(TCA). Each feature is a **reducer** with:

- **`State`:** all the data the feature needs.
- **`Action`:** everything that can happen: user events, effect results, child actions.
- **`body`:** a pure function that changes the state for an action and returns **effects** for the
  async work.

Views hold a **store**, read its state and send actions to it. Side effects go through
**dependency clients** that tests can replace.

Rules:
- State changes only inside a reducer. Views never mutate state; they `store.send(...)`.
- Async work happens only in effects (`.run { send in … }`), which report back by sending an
  action. Never start a `Task` in a reducer or call a client from a view.
- Every outside dependency (network, persistence, clock, UUID) is a `@DependencyClient` read with
  `@Dependency`. Never call `APIClient()` or singletons from a reducer.
- Parents compose children (`Scope`, `.forEach`, `.ifLet`) and react to their actions. Children don't
  know about their parents.

## File structure

```
{{APP_NAME}}/
├── App/
│   ├── {{APP_NAME}}App.swift       @main; owns the root Store
│   ├── AppFeature.swift            Root reducer: Home + navigation stack (Path)
│   ├── AppView.swift               NavigationStack bound to the store's path
│   └── ThirdPartyServices.swift
├── Clients/
│   └── ItemClient.swift            @DependencyClient + DependencyKey + DependencyValues accessor
├── Core/
│   ├── Components/ItemRow.swift    Reusable views with no store
│   └── …                           Networking, Environment, DesignSystem, Extensions
├── Features/
│   ├── Home/
│   │   ├── HomeFeature.swift
│   │   └── HomeView.swift
│   └── ItemDetail/
│       ├── ItemDetailFeature.swift
│       └── ItemDetailView.swift
├── Models/
│   └── Item.swift
└── Resources/
```

New features go in `Features/<Feature>/` as `<Feature>Feature.swift` and `<Feature>View.swift`. New
dependencies go in `Clients/` as `<Name>Client.swift`, and models in `Models/`.

## Responsibilities

| Type | Does | Doesn't |
|---|---|---|
| `HomeFeature` | `State { items, isLoading, errorMessage }`; handles `onAppear`, `retryTapped`, `itemsResponse`; loads through `itemClient` in an effect | Navigate (it only sends `itemTapped`) |
| `HomeView` | Reads `store.items`…; sends `.onAppear`, `.retryTapped`, `.itemTapped(item)` | Hold `@State` for feature data |
| `ItemDetailFeature` | `State { item, isFavorite }`; `favoriteTapped` toggles the favorite | Load data it already has |
| `AppFeature` | Composes `HomeFeature` with `Scope`; owns `path: StackState<Path.State>`; turns `.home(.itemTapped)` into a push | Contain screen logic |
| `AppView` | `NavigationStack(path: $store.scope(state: \.path, action: \.path))`; maps `Path` cases to views | — |
| `ItemClient` | `fetchItems` with `liveValue`, `previewValue`, `testValue` | Hold state |

## Communication

```
{{APP_NAME}}App.store: Store<AppFeature>
   └─▶ AppView ── store.scope(\.home) ─▶ HomeView ── send(.itemTapped) ─┐
                └─ store.scope(\.path) ─▶ ItemDetailView                 │
                                                                         ▼
AppFeature.body:  Scope(\.home) { HomeFeature() }      ◀── .home(.itemTapped(item))
                  Reduce { … state.path.append(.itemDetail(...)) }
                  .forEach(\.path, action: \.path)

HomeFeature: .onAppear ─▶ Effect.run { itemClient.fetchItems() } ─▶ send(.itemsResponse(...))
```

- **View → feature:** `store.send(.someAction)`. Name actions after what happened (`itemTapped`,
  `retryTapped`, `onAppear`), not what to do.
- **Feature → view:** state is `@ObservableState`, so views read `store.property` directly and
  re-render. Bindings use `@Bindable var store` with `$store.property` and a `BindableAction`, or
  `$store.scope(...)` for navigation.
- **Effects:** return `.run { send in … await send(.response(...)) }` for async work and `.none`
  otherwise. Results come back as `Result` actions (`itemsResponse(Result<[Item], any Error>)`).
- **Child → parent:** the parent's reducer matches the child's action, e.g.
  `case let .home(.itemTapped(item))`. The child handles the action as a no-op, and a comment says
  who handles it. For bigger features, use a nested `enum Delegate` action
  (`case delegate(Delegate)`) that only the parent reacts to.
- **Parent → child:** the parent changes the child's state, which it owns through `Scope` or `path`.

## Routing

**Stack navigation** lives in `AppFeature`:

```swift
@Reducer
enum Path {
    case itemDetail(ItemDetailFeature)
}

@ObservableState
struct State: Equatable {
    var home = HomeFeature.State()
    var path = StackState<Path.State>()
}

// in body
case let .home(.itemTapped(item)):
    state.path.append(.itemDetail(ItemDetailFeature.State(item: item)))
    return .none
// …
.forEach(\.path, action: \.path)
```

```swift
// AppView
NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
    HomeView(store: store.scope(state: \.home, action: \.home))
} destination: { store in
    switch store.case {
    case let .itemDetail(store):
        ItemDetailView(store: store)
    }
}
```

- **Root:** `{{APP_NAME}}App` creates `static let store = Store(initialState: AppFeature.State()) { AppFeature() }`
  and shows `AppView(store:)`.
- **Push** a screen by adding a case to `AppFeature.Path`, appending its state to `state.path` when
  the triggering child action arrives, and adding a `case` to the `destination` switch in `AppView`.
  **Pop** from a child with `@Dependency(\.dismiss) var dismiss` and `await dismiss()` in an effect,
  or from the parent with `state.path.removeLast()`.
- **Sheets, alerts and other modals** that belong to one feature use tree navigation:
  `@Presents var destination: Destination.State?`, a `@Reducer enum Destination`,
  `case destination(PresentationAction<Destination.Action>)` and `.ifLet(\.$destination, action: \.destination)`.
  Show them in the view with `.sheet(item: $store.scope(state: \.destination?.someCase, action: \.destination.someCase))`.
- Keep `extension AppFeature.Path.State: Equatable {}` so the root state stays `Equatable`.

## Dependency injection

Dependencies are TCA clients in `Clients/`:

```swift
@DependencyClient
struct ItemClient: Sendable {
    var fetchItems: @Sendable () async throws -> [Item]
}

extension ItemClient: DependencyKey {
    static let liveValue = ItemClient(fetchItems: { /* real implementation */ })
    static let previewValue = ItemClient(fetchItems: { Item.samples })
    static let testValue = ItemClient()   // unimplemented: fails the test if called without an override
}

extension DependencyValues {
    var itemClient: ItemClient {
        get { self[ItemClient.self] }
        set { self[ItemClient.self] = newValue }
    }
}
```

- Reducers read them with `@Dependency(\.itemClient) var itemClient`.
- `liveValue` uses the shared networking layer, e.g. `try await APIClient().send(Endpoint(path: "items"), as: [Item].self)`.
- Use TCA's built-in dependencies (`\.continuousClock`, `\.uuid`, `\.date`, `\.dismiss`) instead of
  calling the system APIs directly.
- There is no `DependencyContainer` in this project.

## Adding a feature

1. If the feature needs outside data, add `Clients/<Name>Client.swift` following `ItemClient.swift`.
   Give it `liveValue`, `previewValue`, `testValue` and a `DependencyValues` accessor.
2. Create `Features/<Feature>/<Feature>Feature.swift`:

   ```swift
   import ComposableArchitecture

   @Reducer
   struct SettingsFeature {
       @ObservableState
       struct State: Equatable {
           var isLoading = false
       }

       enum Action {
           case onAppear
           case settingsResponse(Result<Settings, any Error>)
       }

       @Dependency(\.settingsClient) var settingsClient

       var body: some ReducerOf<Self> {
           Reduce { state, action in
               switch action {
               case .onAppear:
                   state.isLoading = true
                   return .run { send in
                       do {
                           await send(.settingsResponse(.success(try await settingsClient.fetch())))
                       } catch {
                           await send(.settingsResponse(.failure(error)))
                       }
                   }
               case let .settingsResponse(result):
                   state.isLoading = false
                   // update state from result
                   return .none
               }
           }
       }
   }
   ```

3. Create `Features/<Feature>/<Feature>View.swift` with `let store: StoreOf<<Feature>Feature>` (or
   `@Bindable var store` when it needs bindings), and a `#Preview` that builds a `Store` with
   `initialState`.
4. Wire it into a parent:
   - **pushed:** add a case to `AppFeature.Path`, append it in `AppFeature`'s `Reduce`, and add the
     `destination` case in `AppView`
   - **presented:** add `@Presents` and `.ifLet` in the presenting feature
   - **always visible**, e.g. a tab: add its state to the parent and a `Scope`
5. Add the new files to the app target in Xcode.

{{#if tests}}
## Testing

Tests live in `{{APP_NAME}}Tests/`. `HomeFeatureTests.swift` is the sample.

- Use `TestStore` and override every dependency the test touches with `withDependencies`.
  `testValue` is unimplemented, so an unexpected client call fails the test.

  ```swift
  let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
  } withDependencies: {
      $0.itemClient.fetchItems = { Item.samples }
  }
  await store.send(.onAppear) { $0.isLoading = true }
  await store.receive(\.itemsResponse.success) {
      $0.isLoading = false
      $0.items = Item.samples
  }
  ```

- Assert every state change in the `send` and `receive` closures, and `receive` every action an
  effect sends. TestStore fails on anything left unasserted.
- Test navigation on the parent, e.g. `AppFeature`: send `.home(.itemTapped(item))`, then assert
  `$0.path[id: 0] = .itemDetail(...)`.
- Mark the test struct `@MainActor`.

{{/if}}
## Do and don't

- **Do** keep `State` `Equatable` and `@ObservableState`. Mark `Path`/`Destination` state
  `Equatable` with an extension.
- **Do** model effect results as actions (`…Response(Result<…>)`), and handle both success and
  failure.
- **Don't** call clients, `APIClient` or `Task {}` from views. Send an action.
- **Don't** create extra `Store`s for child features. Use `store.scope(state:action:)` from the
  parent.
- **Don't** hold feature data in SwiftUI `@State`. It belongs in the reducer's `State`.
- **Remember** the macro trust prompt: Xcode asks to trust TCA's macros on the first build. On CI,
  pass `-skipMacroValidation`.
