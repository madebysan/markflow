import Foundation
import WebKit

/// Warms up WebKit's background processes (WebContent, GPU, Networking)
/// at app launch so the first document open doesn't eat a ~7s cold-start.
///
/// iOS spawns these processes lazily on first `WKWebView` creation —
/// by creating a throwaway off-screen web view early, we pay that cost
/// before the user taps Browse/Create/Welcome.
///
/// The prewarmer holds a single WKWebView reference for the app lifetime.
/// Shared process pools mean subsequent WKWebViews skip the launch cost.
final class WebViewPrewarmer {
    static let shared = WebViewPrewarmer()

    private var prewarmedView: WKWebView?
    private var hasPrewarmed = false

    private init() {}

    /// Kick off WebKit process launch. Safe to call multiple times — no-ops after the first.
    func prewarm() {
        guard !hasPrewarmed else { return }
        hasPrewarmed = true

        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        prewarmedView = webView

        // Loading an empty HTML string forces the WebContent process to boot
        // and attach, so the next "real" WKWebView inherits a warm pool.
        webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
    }
}
