{{#if has_Firebase}}
import FirebaseCore
{{/if}}
import Foundation
{{#if has_Sentry}}
import Sentry
{{/if}}

/// Starts third-party SDKs. Called once on launch, before the first screen appears.
@MainActor
enum ThirdPartyServices {
    static func configure() {
{{#if has_Sentry}}
        configureSentry()
{{/if}}
{{#if has_Firebase}}
        configureFirebase()
{{/if}}
    }
}
{{#if has_Sentry || has_Firebase}}

private extension ThirdPartyServices {
{{#if has_Sentry}}
    static func configureSentry() {
        // Add your DSN from sentry.io › Project Settings › Client Keys.
        let dsn = ""
        guard !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = AppEnvironment.current.rawValue
        }
    }
{{/if}}
{{#if has_Sentry && has_Firebase}}

{{/if}}
{{#if has_Firebase}}
    static func configureFirebase() {
        // Download GoogleService-Info.plist from the Firebase console and add it to the app target.
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
    }
{{/if}}
}
{{/if}}
