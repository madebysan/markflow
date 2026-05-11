import Foundation

enum PreviewAssets {
    private static let folderName = "preview"
    private static let buildVersionKey = "previewAssetsBuildVersion"

    private static let bundledAssets: [(String, String)] = [
        ("preview", "html"),
        ("preview", "js"),
        ("marked.min", "js"),
        ("highlight.min", "js"),
        ("mermaid.min", "js"),
        ("highlight-github", "css"),
        ("highlight-github-dark", "css"),
        // Custom fonts referenced via @font-face in preview.html — must
        // sit alongside preview.html so WKWebView's read scope can load them.
        ("iAWriterQuattroS-Regular", "ttf"),
        ("iAWriterQuattroS-Bold", "ttf"),
        ("JetBrainsMono-Regular", "ttf"),
        ("JetBrainsMono-Bold", "ttf"),
    ]

    static var folderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(folderName, isDirectory: true)
    }

    static var previewHTMLURL: URL {
        folderURL.appendingPathComponent("preview.html")
    }

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Mirrors bundled preview assets to Documents/preview/ so WKWebView can
    /// load preview.html with allowingReadAccessTo: Documents — letting it
    /// resolve user-saved images that live under Documents/images/.
    /// Only re-copies when the bundle build version changes.
    static func ensure() {
        let current = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0"
        let stored = UserDefaults.standard.string(forKey: buildVersionKey)
        let fm = FileManager.default
        let exists = fm.fileExists(atPath: folderURL.path)

        if exists && stored == current { return }

        if exists {
            try? fm.removeItem(at: folderURL)
        }
        try? fm.createDirectory(at: folderURL, withIntermediateDirectories: true)

        for (name, ext) in bundledAssets {
            guard let src = Bundle.main.url(forResource: name, withExtension: ext) else { continue }
            let dst = folderURL.appendingPathComponent("\(name).\(ext)")
            try? fm.copyItem(at: src, to: dst)
        }

        // Only persist the version if the critical asset actually landed.
        // Otherwise the next launch will retry the copy instead of being
        // stuck with a broken Documents/preview/.
        guard fm.fileExists(atPath: previewHTMLURL.path) else { return }
        UserDefaults.standard.set(current, forKey: buildVersionKey)
    }
}
