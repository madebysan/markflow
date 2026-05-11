import Foundation
import UIKit

enum ImageStore {
    static let folderName = "images"

    static var folderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(folderName, isDirectory: true)
    }

    @discardableResult
    static func save(image: UIImage, suggestedName: String? = nil) throws -> String {
        let fm = FileManager.default
        if !fm.fileExists(atPath: folderURL.path) {
            try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        // Prefer JPEG for photos (smaller), PNG only when transparency matters.
        // Heuristic: if the image has alpha, use PNG; otherwise JPEG q=0.9.
        let hasAlpha = imageHasAlpha(image)
        let ext = hasAlpha ? "png" : "jpg"
        let data: Data?
        if hasAlpha {
            data = image.pngData()
        } else {
            data = image.jpegData(compressionQuality: 0.9)
        }
        guard let data else {
            throw NSError(domain: "ImageStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode image"])
        }

        let base = (suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { name -> String? in
            // Strip filesystem-invalid chars AND markdown-link delimiters so
            // the inserted ![alt](images/<filename>) ref parses correctly.
            let cleaned = name
                .components(separatedBy: CharacterSet(charactersIn: "/\\:?*\"<>|()[]"))
                .joined(separator: "-")
            return cleaned.isEmpty ? nil : cleaned
        } ?? "image"
        let shortID = String(UUID().uuidString.prefix(8))
        let filename = "\(shortID)-\(base).\(ext)"
        let url = folderURL.appendingPathComponent(filename)
        try data.write(to: url)

        return "\(folderName)/\(filename)"
    }

    private static func imageHasAlpha(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let info = cgImage.alphaInfo
        return !(info == .none || info == .noneSkipFirst || info == .noneSkipLast)
    }
}
