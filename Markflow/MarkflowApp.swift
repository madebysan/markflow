import SwiftUI

@main
struct MarkflowApp: App {
    @AppStorage(AppPreferences.themeIDKey) private var themeID: String = AppThemeCatalog.defaultID
    @AppStorage(AppPreferences.appearanceKey) private var appearance: String = AppearancePreference.system.rawValue

    init() {
        // Copy preview assets to Documents so WKWebView can load them with
        // read access scoped to Documents — required for resolving images
        // saved under Documents/images/.
        PreviewAssets.ensure()

        // Kick off WebKit's process launch now so the first document open
        // doesn't pay ~7s of cold-start for the WebContent/GPU/Networking
        // processes. Fire-and-forget; the prewarmer holds a reference.
        WebViewPrewarmer.shared.prewarm()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(AppThemeCatalog.theme(for: themeID).accentColor)
                .preferredColorScheme(AppearancePreference(rawValue: appearance)?.colorScheme)
        }
    }
}
