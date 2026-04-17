import SwiftUI

@main
struct MarkflowApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            DocumentView(document: file.document, sourceURL: file.fileURL)
        }
    }
}
