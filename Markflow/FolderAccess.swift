import Foundation
import UniformTypeIdentifiers
import WebKit

/// Folders the user has let Markflow read, so a file opened from another app
/// can show images stored next to it.
///
/// iOS grants access to the opened file only, not to its folder. When a
/// document refers to images Markflow can't reach, the preview offers to pick
/// the folder once; the bookmark is kept so later visits need no prompt.
enum FolderAccess {
    private static let storeKey = "grantedImageFolders"

    /// Remembers a folder the user picked. Call while its security scope is active.
    static func grant(_ folder: URL) {
        guard let bookmark = try? folder.bookmarkData() else { return }
        var store = bookmarks
        store[folder.standardizedFileURL.path] = bookmark
        UserDefaults.standard.set(store, forKey: storeKey)
    }

    /// The granted folder that contains `documentURL`, if any (the closest one).
    static func grantedFolder(for documentURL: URL) -> URL? {
        let parent = documentURL.deletingLastPathComponent().standardizedFileURL.path
        let match = bookmarks.keys
            .filter { parent == $0 || parent.hasPrefix($0 + "/") }
            .max(by: { $0.count < $1.count })
        guard let match, let data = bookmarks[match] else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale) else {
            forget(match)
            return nil
        }
        // A saved permission only counts if it still works (it can lapse, for
        // example after the app is reinstalled); otherwise ask again.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard scoped, FileManager.default.isReadableFile(atPath: url.path) else {
            forget(match)
            return nil
        }
        if stale { grant(url) }
        return url
    }

    private static func forget(_ path: String) {
        var store = bookmarks
        store[path] = nil
        UserDefaults.standard.set(store, forKey: storeKey)
    }

    /// The folder images should be read from: a granted folder, or the
    /// document's own folder when it sits inside Markflow's Documents.
    static func imageFolder(for documentURL: URL?) -> URL? {
        guard let documentURL else { return nil }
        if isInsideAppDocuments(documentURL) { return documentURL.deletingLastPathComponent() }
        return grantedFolder(for: documentURL)
    }

    /// True when the document refers to local images that can't be shown
    /// until the user grants its folder.
    static func needsFolderAccess(documentURL: URL?, markdown: String) -> Bool {
        guard let documentURL, !isInsideAppDocuments(documentURL),
              grantedFolder(for: documentURL) == nil else { return false }
        let docs = PreviewAssets.documentsURL
        return relativeImagePaths(in: markdown).contains { path in
            !FileManager.default.fileExists(atPath: docs.appendingPathComponent(path).path)
        }
    }

    /// Relative image references in Markdown image syntax or <img src>.
    static func relativeImagePaths(in markdown: String) -> [String] {
        let patterns = [#"!\[[^\]]*\]\(\s*<?([^)\s>]+)"#, #"<img[^>]+src\s*=\s*["']([^"']+)["']"#]
        var paths: [String] = []
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let text = markdown as NSString
            for match in regex.matches(in: markdown, range: NSRange(location: 0, length: text.length)) {
                let raw = text.substring(with: match.range(at: 1))
                if raw.range(of: #"^([a-z][a-z0-9+.-]*:|/|#)"#, options: [.regularExpression, .caseInsensitive]) != nil { continue }
                paths.append(raw.removingPercentEncoding ?? raw)
            }
        }
        return paths
    }

    private static var bookmarks: [String: Data] {
        UserDefaults.standard.dictionary(forKey: storeKey) as? [String: Data] ?? [:]
    }

    private static func isInsideAppDocuments(_ url: URL) -> Bool {
        let docs = PreviewAssets.documentsURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path.hasPrefix(docs + "/")
    }
}

/// Serves relative images to the preview as `markflow-file://image/<path>`:
/// first from the document's folder (when Markflow may read it), then from
/// Markflow's Documents, where images inserted in the app live. Paths can't
/// leave those folders.
final class DocumentImageSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "markflow-file"
    static let basePath = "markflow-file://image/"

    /// The document's folder, or nil when Markflow can't read it.
    var folder: URL?

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url else { return task.didFailWithError(URLError(.badURL)) }
        let relative = String(url.path.drop(while: { $0 == "/" }))
        let roots = [folder, PreviewAssets.documentsURL].compactMap { $0 }
        for root in roots {
            let scoped = root.startAccessingSecurityScopedResource()
            defer { if scoped { root.stopAccessingSecurityScopedResource() } }
            let base = root.standardizedFileURL.path
            let file = root.appendingPathComponent(relative).standardizedFileURL
            guard file.path.hasPrefix(base + "/"), let data = try? Data(contentsOf: file) else { continue }
            let mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            task.didReceive(URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil))
            task.didReceive(data)
            task.didFinish()
            return
        }
        task.didFailWithError(URLError(.fileDoesNotExist))
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}
