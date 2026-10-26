# {{DISPLAY_NAME}}

{{UI_FRAMEWORK}} app built with **{{PATTERN_NAME}}**. Requires iOS {{DEPLOYMENT_TARGET}} or later.

## Getting started

1. Open `{{APP_NAME}}.xcodeproj`.
2. Pick a scheme (for example `{{FIRST_SCHEME}}`) and run.
{{#if swiftlint}}
3. Install SwiftLint (`brew install swiftlint`); it runs on every build.
{{/if}}
{{#if agentguide}}

Working with a coding agent? `AGENTS.md` describes the project, and `docs/ARCHITECTURE.md` describes how
{{PATTERN_NAME}} is applied here: the file structure, how the types communicate, and how navigation
works. `CLAUDE.md` imports `AGENTS.md` for Claude Code.
{{/if}}

## Environments

Each environment has its own scheme, a Debug and a Release configuration, and an xcconfig file in
`Configuration/`. Its values reach the code through Info.plist and `AppEnvironment`.

| Environment | Scheme | Bundle ID | Display name | API base URL |
|---|---|---|---|---|
{{ENV_TABLE}}

To change an environment's values, edit its file in `Configuration/`. Settings shared by every
environment go in `Configuration/Shared.xcconfig`.

## Packages

{{PACKAGES_LIST}}
{{#if fastlane}}

## fastlane

```bash
bundle install
{{#if tests}}
bundle exec fastlane tests
{{/if}}
```

TestFlight lanes:

{{FASTLANE_LANE_LIST}}
{{/if}}
