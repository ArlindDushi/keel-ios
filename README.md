# Keel

**An iOS & iPadOS project generator for macOS.**

Starting a new iOS app usually means spending a day on the same setup: schemes for each environment,
bundle IDs, xcconfig files, a folder structure, networking, SwiftLint, fastlane, tests. Keel does it in
a minute. Fill in one form, click **Create Project**, and open a project that builds and runs.

Keel is free and open source under the [MIT License](LICENSE), and anyone can use it.

## What you get

A ready-to-build Xcode project with:

- **An environment setup that scales**: one scheme per environment (`Weather Dev`, `Weather Staging`,
  `Weather Production`, …), each with Debug and Release configurations and its own bundle ID, app name
  and API base URL
- **The architecture you picked**, with a folder layout that follows its conventions
- **A working sample flow** (a list screen that opens a detail screen), built the way the pattern
  intends, so you can see where new code belongs
- **Shared building blocks**: an async/await API client, environment access, design tokens and extensions
- **Your SDKs** added through Swift Package Manager
- **Tooling you opted into**: SwiftLint, unit and UI tests, fastlane lanes, and a git repository with
  a first commit

Every combination of pattern and UI framework is tested: generated, built, and run on the iOS simulator
with its unit and UI tests.

## Using Keel

The window has the form on the left and a live preview of the files that will be created on the right.

### 1. Project

| Field | What it's for |
|---|---|
| App name | The Xcode target and project name, e.g. `Weather`. Letters and digits only. |
| Display name | The name under the app icon, e.g. `Weather Pro`. |
| Bundle ID prefix | Your reverse domain, e.g. `com.acme`. Keel remembers it and suggests the bundle ID from it. |
| Bundle ID | The App Store bundle identifier, e.g. `com.acme.weather`. |
| Organization | The copyright holder in every file header, including files you add later in Xcode. |
| Author | The "Created by" name in the generated files' headers. |
| Team ID | Your Apple Developer team ID, for automatic signing. Optional. |
| Minimum iOS / Devices | iOS 17 or later; iPhone only, or iPhone + iPad. |
| Location | The folder the project folder is created in. |

Every generated Swift file starts with:

```swift
//
//  HomeView.swift
//  Weather
//
//  Created by Jane Appleseed on 22/10/2026.
//  Copyright © 2026 Acme Inc. All rights reserved.
//
```

### 2. Environments

Each environment is a separate build of your app. Dev, Staging and Production are there to start with;
add, rename or remove as many as you need, and tick the one that ships to the App Store.

| Environment | Bundle ID | Home screen name | Scheme |
|---|---|---|---|
| Dev | `com.acme.weather.dev` | Weather Dev | `Weather Dev` |
| Staging | `com.acme.weather.staging` | Weather Staging | `Weather Staging` |
| Production | `com.acme.weather` | Weather | `Weather Production` |

- **Bundle ID suffix** makes each environment a separate app. You can install all of them side by side,
  each keeps its own data and login, and each can have its own push certificates, Firebase project and
  TestFlight group.
- **Name suffix** tells the builds apart on the home screen.
- **API base URL** is the server that environment talks to.

The full bundle ID and name are shown under each field as you type. In the generated project these
values live in `Configuration/<Environment>.xcconfig`, and code reads them through `AppEnvironment`:

```swift
let url = AppEnvironment.apiBaseURL      // https://staging.api.example.com in the Staging scheme
if AppEnvironment.current.isProduction { … }
```

### 3. Architecture

Choose **SwiftUI** or **UIKit**, then a pattern. Patterns that don't fit the framework are greyed out.

| Pattern | SwiftUI | UIKit | Generated layout |
|---|---|---|---|
| **MVC** | — | ✓ | `Features/<Feature>/{ViewController, View}`, `Models`, `Services` |
| **MVVM + Coordinator** | ✓ with a NavigationStack router | ✓ with coordinators | `Features/<Feature>/{View, ViewModel}`, `Navigation` or `Coordinators`, `Domain/{Models, Services}` |
| **VIPER** | ✓ | ✓ | `Modules/<Module>/{Contracts, View, Interactor, Presenter, Router, ModuleBuilder}`, `Entities`, `Services` |
| **Clean Swift (VIP)** | ✓ | ✓ | `Scenes/<Scene>/{Models, View, Interactor, Presenter, Router, Worker, Configurator}`, `Models`, `Services` |
| **The Composable Architecture** | ✓ | — | `Features/<Feature>/{Feature, View}`, `Clients`, `Models` |

For example, **MVVM + SwiftUI** for an app called Weather produces:

```
Weather/
├── Configuration/            Shared.xcconfig + one .xcconfig per environment
├── Weather/
│   ├── App/                  WeatherApp, DependencyContainer, ThirdPartyServices
│   ├── Core/
│   │   ├── Components/       Reusable views
│   │   ├── DesignSystem/     Spacing and other tokens
│   │   ├── Environment/      AppEnvironment
│   │   ├── Extensions/
│   │   └── Networking/       APIClient, Endpoint, APIError
│   ├── Domain/
│   │   ├── Models/
│   │   └── Services/
│   ├── Features/
│   │   ├── Home/             HomeView, HomeViewModel
│   │   └── ItemDetail/       ItemDetailView, ItemDetailViewModel
│   ├── Navigation/           Router, Route, RootView
│   └── Resources/            Assets, Info.plist, PrivacyInfo, Localizable.xcstrings
├── WeatherTests/             Swift Testing unit tests
├── WeatherUITests/
├── fastlane/                 Appfile, Fastfile
├── Scripts/swiftlint.sh
├── .swiftlint.yml
├── Gemfile
├── README.md                 Describes the project's environments and packages
├── AGENTS.md                 Guide for coding agents; CLAUDE.md imports it
├── CLAUDE.md
├── docs/ARCHITECTURE.md      How the chosen pattern is applied: structure, communication, routing
└── Weather.xcodeproj
```

### 4. Remote SDKs

Tick the packages you want; each is added "up to next major" from the version shown.

| Category | Packages |
|---|---|
| Networking | Alamofire (the generated API client then uses it instead of URLSession) |
| Images | Kingfisher, SDWebImage |
| UI | Lottie, SnapKit (UIKit only) |
| Storage | KeychainAccess |
| Architecture | Factory |
| Monitoring | Sentry, Firebase (pick the products you need) |
| Monetization | RevenueCat |

Use **Add Package…** for any other Swift package: paste its URL, pick a version rule, and list the
products to link.

### 5. Tooling

| Option | What's added |
|---|---|
| SwiftLint | `.swiftlint.yml` and a build phase that lints on every build |
| Unit and UI tests | A Swift Testing unit test target and an XCUITest target, run by every scheme |
| fastlane | A `Gemfile` and a `Fastfile` with a `beta_<environment>` TestFlight lane for each environment |
| Git repository | `git init` on `main` with an initial commit |
| Agent guide | `AGENTS.md` (commands, environments, conventions), `docs/ARCHITECTURE.md` for the chosen pattern and UI framework (file structure, communication, routing, DI, adding a feature, testing), and a `CLAUDE.md` that imports `AGENTS.md` |
| Keep project.yml | The XcodeGen spec, so you can regenerate the project later |

### 6. Create

When something needs fixing, the bottom of the preview says so. Click **N things to fix** to highlight
those fields and jump to each one in turn. Then click **Create Project** (⌘↩).

## After generating

- **SwiftLint**: install it with `brew install swiftlint`. Until you do, builds show a warning instead
  of linting.
- **Sentry**: add your DSN in `<AppName>/App/ThirdPartyServices.swift`; Sentry starts once it's set.
- **Firebase**: add `GoogleService-Info.plist` from the Firebase console to the app target; Firebase is
  configured on launch once the file is there.
- **TCA**: the first time you build, Xcode asks you to trust the Composable Architecture's macros.
  Click **Trust & Enable**. On CI, pass `-skipMacroValidation` to `xcodebuild`.
- **fastlane**: run `bundle install`, then e.g. `bundle exec fastlane beta_staging`.

## Requirements

- macOS 15 or later
- Xcode 16 or later

## Building Keel

```bash
git clone https://github.com/ArlindDushi/keel-ios.git
cd keel-ios
open Keel.xcodeproj
```

Then run the **Keel** scheme.

## Contributing

### Repository layout

| Path | Purpose |
|---|---|
| `App/` | The macOS SwiftUI app: form, preview, generation sheet |
| `Sources/KeelCore/` | Building blocks that don't depend on iOS: template rendering, file trees, git |
| `Sources/KeeliOS/` | The iOS generator: models, validation, XcodeGen spec |
| `Sources/KeeliOS/Resources/Templates/` | Files copied into generated projects |
| `Sources/KeeliOS/Resources/sdk-catalog.json` | The curated SDK list |
| `Tests/` | `KeelCoreTests` and `KeeliOSTests` |
| `Keel.xcodeproj` | Xcode project of the macOS app. `App/` is a synchronized folder, so new files show up without editing the project |

`KeelCore` knows nothing about iOS, so generators for other stacks (React Native, Android, …) can
reuse it.

### Adding an SDK

Add an entry to `Sources/KeeliOS/Resources/sdk-catalog.json`:

```json
{
  "id": "kingfisher",
  "name": "Kingfisher",
  "summary": "Downloading and caching images from the web.",
  "category": "Images",
  "url": "https://github.com/onevcat/Kingfisher",
  "version": "8.14.0",
  "products": ["Kingfisher"]
}
```

Optional keys: `defaultProducts`, `uiFrameworks` (`["uikit"]` or `["swiftui"]`) and `linkerFlags`.

### Editing templates

`Templates/Common` is copied into every project, then `Templates/<Pattern>/<SwiftUI|UIKit>`.

- `AppName` in a path becomes the app name, and a leading `_.` becomes `.` (`_.gitignore`).
- `[condition]` at the start of a file or folder name keeps it only when the condition holds,
  e.g. `[tests]AppNameTests` or `[!tca]DependencyContainer.swift`.
- In file contents, `{{APP_NAME}}`-style variables are replaced. Lines between `{{#if condition}}`,
  `{{else}}` and `{{/if}}` (each on its own line) are kept or dropped.
- Conditions support `!`, `&&` and `||`. Available flags:
  - the UI framework: `swiftui`, `uikit`
  - the pattern: `mvc`, `mvvm`, `viper`, `clean_swift`, `tca`
  - options: `tests`, `swiftlint`, `fastlane`, `git`, `agentguide`, `universal`, `has_team`
  - packages: `has_<Product>` for each linked product, plus `has_Firebase`
- Variables are listed in `ProjectConfiguration+Template.swift`.
- Swift files get their header on generation, so don't add one in templates.

To add a pattern, add a case to `ArchitecturePattern` and a template folder for each UI framework it
supports, including its `[agentguide]docs/ARCHITECTURE.md`.

Each pattern folder's `[agentguide]docs/ARCHITECTURE.md` describes that folder's sample code. When you
change the sample code, update the guide too. A test checks that every `.swift` file the guide names
is generated.

### Tests

```bash
swift test                                                   # renderer, validation, every combination
KEEL_E2E=1 swift test --filter generatedProjectBuilds        # also builds each generated project (slow)
KEEL_SAMPLES=/tmp/samples swift test --filter writeSamples   # writes every combination to inspect
```

## License

Keel is released under the [MIT License](LICENSE).

**Projects generated by Keel are yours.** The code Keel writes into your project, including the code
that comes from its templates, belongs to you. You can use, change, sell and license it however you
like. You don't need to credit Keel or include its license in your app.
