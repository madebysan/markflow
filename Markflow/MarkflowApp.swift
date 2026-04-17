import SwiftUI

@main
struct MarkflowApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            DocumentView(document: file.$document)
        }
    }
}
