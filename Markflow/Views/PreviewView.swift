import SwiftUI
import WebKit

struct PreviewView: UIViewRepresentable {
    let markdown: String
    var baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator

        // Pinch-to-zoom
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 5.0
        webView.scrollView.bouncesZoom = true

        context.coordinator.webView = webView

        loadTemplate(into: webView)
        context.coordinator.pendingMarkdown = markdown

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.pendingMarkdown = markdown
        if context.coordinator.isReady {
            render(markdown: markdown, in: webView)
        }
    }

    private func loadTemplate(into webView: WKWebView) {
        let url = PreviewAssets.previewHTMLURL
        // Grant read access to the whole Documents folder so images saved
        // under Documents/images/ can be loaded by the page.
        webView.loadFileURL(url, allowingReadAccessTo: PreviewAssets.documentsURL)
    }

    private func render(markdown: String, in webView: WKWebView) {
        let escaped = Self.jsonString(from: markdown)
        webView.evaluateJavaScript("render(\(escaped))", completionHandler: nil)
    }

    private static func jsonString(from value: String) -> String {
        guard let data = try? JSONEncoder().encode([value]),
              let json = String(data: data, encoding: .utf8),
              json.count >= 2
        else {
            return "\"\""
        }
        let trimmed = String(json.dropFirst().dropLast())
        return trimmed
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var pendingMarkdown: String = ""
        var isReady: Bool = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
            // Tell preview.js where to resolve relative image paths from.
            let basePath = "file://" + PreviewAssets.documentsURL.path + "/"
            let escapedBase = PreviewView.jsonString(from: basePath)
            webView.evaluateJavaScript("window.imageBasePath = \"\(escapedBase)\";", completionHandler: nil)

            let escaped = PreviewView.jsonString(from: pendingMarkdown)
            webView.evaluateJavaScript("render(\(escaped))", completionHandler: nil)
        }
    }
}
