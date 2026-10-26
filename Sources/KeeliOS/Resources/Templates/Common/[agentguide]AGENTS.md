# {{DISPLAY_NAME}}: guide for coding agents

{{DISPLAY_NAME}} is an iOS {{DEPLOYMENT_TARGET}}+ app written in Swift with {{UI_FRAMEWORK}} and **{{PATTERN_NAME}}**.
This file covers the whole project. Before you write or move code, read
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). It describes the file structure, how the pattern's
types talk to each other, and how navigation works.

@docs/ARCHITECTURE.md

## Commands

```bash
# Build (pick any scheme; there is one per environment)
xcodebuild build -project {{APP_NAME}}.xcodeproj -scheme "{{FIRST_SCHEME}}" \
  -destination "generic/platform=iOS Simulator"
{{#if tests}}

# Unit and UI tests (find a simulator name with `xcrun simctl list devices available`)
xcodebuild test -project {{APP_NAME}}.xcodeproj -scheme "{{FIRST_SCHEME}}" \
  -destination "platform=iOS Simulator,name=<simulator name>"
{{/if}}
{{#if swiftlint}}

# Lint (also runs as a build phase)
swiftlint
{{/if}}
{{#if fastlane && tests}}

# Tests through fastlane (run `bundle install` once first)
bundle exec fastlane tests
{{/if}}
```
{{#if tca}}

The Composable Architecture uses Swift macros. When running `xcodebuild` from the command line or on
CI, pass `-skipMacroValidation`.
{{/if}}
{{#if fastlane}}

TestFlight lanes (after `bundle install`). They upload builds, so run them only when the user asks:

{{FASTLANE_LANE_LIST}}
{{/if}}

## Environments

Each environment is a separate scheme with its own bundle ID, display name and API base URL:

| Environment | Scheme | Bundle ID | Display name | API base URL |
|---|---|---|---|---|
{{ENV_TABLE}}

- The values are in `Configuration/<Environment>.xcconfig`. Settings that every environment shares go
  in `Configuration/Shared.xcconfig`.
- They reach code through `Info.plist` and `AppEnvironment` (`{{APP_NAME}}/Core/Environment/AppEnvironment.swift`):
  `AppEnvironment.current`, `AppEnvironment.apiBaseURL`, `AppEnvironment.current.isProduction`.
- Never hard-code URLs or branch on bundle IDs. To add a per-environment value, add it to every
  xcconfig file, expose it in `Info.plist`, and read it in `AppEnvironment`.

## Shared building blocks

| Where | What | How to use it |
|---|---|---|
| `Core/Networking/APIClient.swift` | `APIClientProtocol` / `APIClient` | `try await apiClient.send(endpoint, as: Response.self)`. It decodes with `JSONDecoder.api`. |
| `Core/Networking/Endpoint.swift` | `Endpoint` | Declare endpoints in the service that owns them, e.g. `extension Endpoint { static let items = Endpoint(path: "items") }`. Use `Endpoint.json(_:method:body:)` for JSON bodies. |
| `Core/Networking/APIError.swift` | `APIError` | Every networking failure is mapped to this type, and its `errorDescription` is ready to show to the user. |
| `Core/Extensions/JSONCoding+API.swift` | `JSONDecoder.api`, `JSONEncoder.api` | snake_case keys and ISO 8601 dates. |
| `Core/DesignSystem/Spacing.swift` | `Spacing` | Use `Spacing.small`, `Spacing.medium` and so on instead of literal numbers. |
{{#if uikit}}
| `Core/Extensions/UIView+Layout.swift` | `pinEdges(to:safeArea:)`, `center(in:)` | Auto Layout helpers. Prefer them to writing constraints by hand. |
{{/if}}
| `App/ThirdPartyServices.swift` | `ThirdPartyServices.configure()` | SDK setup, called once at launch. Configure new SDKs here. |
{{#if !tca}}
| `App/DependencyContainer.swift` | `DependencyContainer` | The composition root. It creates shared services once; features receive them through their initializers. |
{{/if}}
{{#if has_Alamofire}}

`APIClient` is built on Alamofire. Keep Alamofire inside `APIClient` so features depend only on
`APIClientProtocol`.
{{/if}}

{{#if tca}}
Dependencies are TCA clients (see `Clients/`), registered with `DependencyKey` and read with
`@Dependency`. Never create a client inside a reducer.
{{else}}
To add a service:
1. Declare a `Sendable` protocol and a struct that takes `any APIClientProtocol`.
2. Create it in `DependencyContainer`.
3. Pass it to features as the protocol type.

Never create services inside screens.
{{/if}}

## Conventions

- Swift concurrency only: `async`/`await` and `Task`, no completion handlers or Combine in new code.
  UI types are `@MainActor`; services and models are `Sendable`.
- Every user-facing string uses `String(localized:)` (or a `Text` literal) and goes in
  `Resources/Localizable.xcstrings`.
- Don't add file headers by hand. Xcode adds them from the project's template macros.
{{#if swiftui}}
- Each view file ends with a `#Preview` that uses sample data (`Item.samples` is the example).
{{/if}}
{{#if uikit}}
- Views are built in code, with no storyboards or XIBs. A view controller sets `view = customView` in
  `loadView()`, and `init?(coder:)` is marked `@available(*, unavailable)`.
{{/if}}
{{#if tests}}
- Tests use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`). Test types that touch UI
  types are `@MainActor`. UI tests in `{{APP_NAME}}UITests` use XCTest.
{{/if}}
{{#if swiftlint}}
- Code must pass SwiftLint (`.swiftlint.yml`). Fix the warnings; don't disable the rules.
{{/if}}
- The sample `Home` and `ItemDetail` screens and `Item` are placeholders. Use them as a template and
  replace them; don't build on top of them.

## Packages

{{PACKAGES_LIST}}

Add packages through Xcode (*File ▸ Add Package Dependencies…*).

## Working rules

1. Follow the pattern in `docs/ARCHITECTURE.md`. A new feature looks like the existing ones: same
   folders, same file names, same way of communicating.
{{#if tests}}
2. Every new feature comes with unit tests, as described in `docs/ARCHITECTURE.md`.
{{else}}
2. Keep logic out of views so it can be tested later.
{{/if}}
{{#if tests}}
3. Build and run the tests before you finish.
{{else}}
3. Build before you finish.
{{/if}}
4. The Xcode project uses regular groups, so a new file builds only once it is added to its target.
   Add it in Xcode or with a tool that edits the project properly. Don't hand-edit
   `project.pbxproj`. If you can't add the file, tell the user which files need adding to which
   target.
