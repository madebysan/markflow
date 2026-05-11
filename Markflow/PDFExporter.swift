import Foundation
import WebKit
import UIKit

final class PDFExporter: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    // Strong references to in-flight exporters so they don't get released
    // before createPDF's async completion fires.
    private static var active: [PDFExporter] = []

    private let webView: WKWebView
    private let markdown: String
    private let font: DocumentFont
    private let fontSize: Double
    private let title: String
    private let completion: (Result<URL, Error>) -> Void
    private var didFinishOnce = false

    private init(
        markdown: String,
        font: DocumentFont,
        fontSize: Double,
        title: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        self.markdown = markdown
        self.font = font
        self.fontSize = fontSize
        self.title = title
        self.completion = completion

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let userController = WKUserContentController()
        config.userContentController = userController

        // US Letter at 72dpi.
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        webView = WKWebView(frame: pageRect, configuration: config)

        super.init()
        userController.add(self, name: "renderDone")
        webView.navigationDelegate = self
    }

    static func export(
        markdown: String,
        font: DocumentFont,
        fontSize: Double,
        title: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let exporter = PDFExporter(
            markdown: markdown,
            font: font,
            fontSize: fontSize,
            title: title,
            completion: completion
        )
        active.append(exporter)
        exporter.start()
    }

    // MARK: - Lifecycle

    private func start() {
        // Park the WKWebView in the key window's view hierarchy (invisible)
        // so rendering actually happens. Off-screen WKWebViews that are not
        // attached can short-circuit layout/JS and produce blank PDFs.
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow }) else {
            // No key window (background, scene transition) — fail fast so
            // the caller's `exportingPDF` flag gets reset and the user can
            // retry.
            finish(.failure(NSError(
                domain: "PDFExporter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Markflow can't export PDF right now. Try again."]
            )))
            return
        }
        webView.alpha = 0
        window.addSubview(webView)

        webView.loadFileURL(
            PreviewAssets.previewHTMLURL,
            allowingReadAccessTo: PreviewAssets.documentsURL
        )
    }

    private func finish(_ result: Result<URL, Error>) {
        // Guard against double-completion: didFail + renderDone races, or
        // the same race firing across the createPDF main-queue dispatch.
        guard !didFinishOnce else { return }
        didFinishOnce = true
        webView.removeFromSuperview()
        completion(result)
        Self.active.removeAll(where: { $0 === self })
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let basePath = "file://" + PreviewAssets.documentsURL.path + "/"
        let escapedBase = Self.jsonString(from: basePath)
        let family = Self.jsonString(from: font.cssFamily)
        let stretch = Self.jsonString(from: font.cssStretch)
        let escapedMD = Self.jsonString(from: markdown)

        let js = """
        window.imageBasePath = \(escapedBase);
        setFontPreferences(\(family), \(stretch), \(Int(fontSize)));
        render(\(escapedMD)).then(function() {
            window.webkit.messageHandlers.renderDone.postMessage('done');
        });
        """

        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "renderDone" else { return }
        // Small delay so any async resources (mermaid SVGs, lazy images)
        // settle before snapshotting.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.generatePDF()
        }
    }

    // MARK: - PDF generation

    private func generatePDF() {
        let pdfConfig = WKPDFConfiguration()
        webView.createPDF(configuration: pdfConfig) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                do {
                    let url = try self.writeTempPDF(data: data)
                    DispatchQueue.main.async {
                        self.finish(.success(url))
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.finish(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.finish(.failure(error))
                }
            }
        }
    }

    private func writeTempPDF(data: Data) throws -> URL {
        let baseName = (title as NSString).deletingPathExtension
        let safeTitle = sanitize(baseName.isEmpty ? "Document" : baseName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeTitle).pdf")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        try data.write(to: url)
        return url
    }

    private func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?*\"<>|")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "Document" : cleaned
    }

    private static func jsonString(from value: String) -> String {
        guard let data = try? JSONEncoder().encode([value]),
              let json = String(data: data, encoding: .utf8),
              json.count >= 2
        else {
            return "\"\""
        }
        return String(json.dropFirst().dropLast())
    }
}
