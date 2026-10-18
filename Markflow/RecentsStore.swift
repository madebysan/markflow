import Foundation
import Observation

struct RecentEntry: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let bookmarkData: Data
    var lastOpened: Date
}

@Observable
final class RecentsStore {
    static let shared = RecentsStore()

    private let storageKey = "recentDocuments"
    private let maxEntries = 4

    private(set) var entries: [RecentEntry] = []

    private init() {
        load()
    }

    // MARK: - Public API

    func add(url: URL) {
        let bookmark: Data
        do {
            bookmark = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            return
        }

        var next = entries.filter { $0.bookmarkData != bookmark }
        next.insert(
            RecentEntry(
                id: UUID(),
                displayName: url.lastPathComponent,
                bookmarkData: bookmark,
                lastOpened: Date()
            ),
            at: 0
        )
        if next.count > maxEntries {
            next = Array(next.prefix(maxEntries))
        }
        entries = next
        save()
    }

    func remove(_ entry: RecentEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    /// Resolves a bookmark to a URL. Returns nil if the bookmark is unresolvable
    /// (file moved/deleted/permission revoked) and prunes the entry.
    func resolve(_ entry: RecentEntry) -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: entry.bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale { remove(entry) }
            return url
        } catch {
            remove(entry)
            return nil
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([RecentEntry].self, from: data) else {
            return
        }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
