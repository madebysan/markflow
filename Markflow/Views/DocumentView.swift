import SwiftUI
import UniformTypeIdentifiers

struct DocumentView: View {
    let documentText: String
    let sourceURL: URL?
    let onClose: () -> Void

    @State private var mode: Mode = .preview
    @State private var workingText: String = ""
    @State private var didInit: Bool = false

    @State private var showExitConfirmation: Bool = false
    @State private var showExporter: Bool = false
    @State private var saveAlert: SaveAlert?

    enum Mode: String, CaseIterable, Identifiable {
        case preview, edit
        var id: String { rawValue }
        var label: String {
            switch self {
            case .preview: return "Preview"
            case .edit: return "Edit"
            }
        }
    }

    var hasUnsavedChanges: Bool {
        workingText != documentText
    }

    var exportFileName: String {
        let base = sourceURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
        return "\(base)-edited.md"
    }

    private var newFileDefaultName: String {
        if let base = sourceURL?.deletingPathExtension().lastPathComponent {
            return "\(base)-copy"
        }
        return "Untitled"
    }

    private var markdownType: UTType {
        UTType("net.daringfireball.markdown") ?? .plainText
    }

    var body: some View {
        Group {
            switch mode {
            case .preview:
                PreviewView(markdown: workingText, baseURL: nil)
            case .edit:
                EditView(text: $workingText)
            }
        }
        .onAppear {
            if !didInit {
                workingText = documentText
                didInit = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    attemptClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }

            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: exportedFileURL(),
                    preview: SharePreview(exportFileName)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(workingText.isEmpty)
            }
        }
        .confirmationDialog(
            "You have unsaved changes",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            if sourceURL != nil {
                Button("Save") { saveToSource() }
            }
            Button("Save as New File…") { showExporter = true }
            Button("Discard Changes", role: .destructive) { onClose() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(sourceURL != nil
                 ? "Save overwrites the original file. Save as New File keeps the original untouched."
                 : "Pick a location to save your new markdown file, or discard your work.")
        }
        .fileExporter(
            isPresented: $showExporter,
            document: MarkdownFileDocument(text: workingText),
            contentType: markdownType,
            defaultFilename: newFileDefaultName
        ) { result in
            switch result {
            case .success:
                onClose()
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == NSUserCancelledError { return }
                saveAlert = SaveAlert(
                    title: "Couldn't save",
                    message: error.localizedDescription
                )
            }
        }
        .alert(
            saveAlert?.title ?? "",
            isPresented: Binding(
                get: { saveAlert != nil },
                set: { if !$0 { saveAlert = nil } }
            ),
            presenting: saveAlert
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }

    // MARK: - Actions

    private func attemptClose() {
        if hasUnsavedChanges {
            showExitConfirmation = true
        } else {
            onClose()
        }
    }

    private func saveToSource() {
        guard let url = sourceURL else { return }
        do {
            try workingText.write(to: url, atomically: true, encoding: .utf8)
            onClose()
        } catch {
            saveAlert = SaveAlert(
                title: "Couldn't save",
                message: error.localizedDescription
            )
        }
    }

    private func exportedFileURL() -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(exportFileName)
        try? workingText.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}

// MARK: - Save error alert model

private struct SaveAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - FileDocument for Save as New File

struct MarkdownFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [UTType("net.daringfireball.markdown") ?? .plainText, .plainText]
    }

    static var writableContentTypes: [UTType] {
        [UTType("net.daringfireball.markdown") ?? .plainText]
    }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
