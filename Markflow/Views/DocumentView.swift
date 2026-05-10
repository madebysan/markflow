import SwiftUI
import UniformTypeIdentifiers

struct DocumentView: View {
    let documentText: String
    let sourceURL: URL?
    let onClose: () -> Void

    @AppStorage(AppPreferences.newFileModeKey) private var newFileModeRaw: String = NewFileMode.edit.rawValue

    @State private var mode: Mode = .preview
    @State private var workingText: String = ""
    @State private var didInit: Bool = false

    @State private var currentURL: URL?
    @State private var displayName: String = "Untitled.md"

    @State private var showExitConfirmation: Bool = false
    @State private var showExporter: Bool = false
    @State private var showRenameAlert: Bool = false
    @State private var renameInput: String = ""
    @State private var saveAlert: SaveAlert?
    @State private var showSettings: Bool = false

    @State private var swipeOffset: CGFloat = 0
    private let edgeThreshold: CGFloat = 24
    private let dismissThreshold: CGFloat = 90

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

    var body: some View {
        content
            .navigationTitle(displayName)
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(.automatic, for: .navigationBar)
            .onAppear(perform: initializeOnFirstAppear)
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) {
                modeTogglePill
                    .padding(.bottom, 10)
            }
            .offset(x: swipeOffset)
            .simultaneousGesture(swipeBackGesture)
            .confirmationDialog(
                "Unsaved changes",
                isPresented: $showExitConfirmation,
                titleVisibility: .visible
            ) {
                exitConfirmationActions
            } message: {
                Text(exitConfirmationMessage)
            }
            .fileExporter(
                isPresented: $showExporter,
                document: MarkdownFileDocument(text: workingText),
                contentType: markdownType,
                defaultFilename: newFileDefaultName,
                onCompletion: handleExporterResult
            )
            .alert("Rename", isPresented: $showRenameAlert) {
                TextField("Name", text: $renameInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Rename") { performRename() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(currentURL != nil
                    ? "Rename will move the file in place."
                    : "Sets the suggested name when you save this file.")
            }
            .alert(
                saveAlert?.title ?? "",
                isPresented: saveAlertBinding,
                presenting: saveAlert
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { alert in
                Text(alert.message)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }

    // MARK: - Body fragments

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .preview:
            PreviewView(markdown: workingText, baseURL: nil)
        case .edit:
            EditView(text: $workingText)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: attemptClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("Close")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    renameTapped()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button {
                    showExporter = true
                } label: {
                    Label("Save to Files", systemImage: "square.and.arrow.down")
                }

                ShareLink(
                    item: MarkdownExport(filename: exportFileName, text: workingText),
                    preview: SharePreview(exportFileName)
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("More options")
        }
    }

    private var swipeBackGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                guard value.startLocation.x < edgeThreshold else { return }
                swipeOffset = max(0, value.translation.width)
            }
            .onEnded { value in
                let startedAtEdge = value.startLocation.x < edgeThreshold
                let pastThreshold = value.translation.width > dismissThreshold
                if startedAtEdge && pastThreshold {
                    attemptClose()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        swipeOffset = 0
                    }
                }
            }
    }

    private var modeTogglePill: some View {
        HStack(spacing: 0) {
            modeIconButton(target: .preview, icon: "eye", label: "Preview")
            modeIconButton(target: .edit, icon: "pencil", label: "Edit")
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        )
    }

    private func modeIconButton(target: Mode, icon: String, label: String) -> some View {
        let isSelected = mode == target
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                mode = target
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : .primary.opacity(0.55))
                .frame(width: 48, height: 32)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(.tint)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) mode")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var exitConfirmationActions: some View {
        if currentURL != nil {
            Button("Save") { saveToSource() }
        }
        Button("Save as New File…") { showExporter = true }
        Button("Discard Changes", role: .destructive) { onClose() }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Derived

    private var hasUnsavedChanges: Bool {
        workingText != documentText
    }

    private var exportFileName: String {
        "\(baseName)-edited.md"
    }

    private var newFileDefaultName: String {
        baseName == "Untitled" ? "Untitled" : "\(baseName)-copy"
    }

    private var baseName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Untitled" }
        let url = URL(fileURLWithPath: trimmed)
        let base = url.deletingPathExtension().lastPathComponent
        return base.isEmpty ? "Untitled" : base
    }

    private var markdownType: UTType {
        UTType("net.daringfireball.markdown") ?? .plainText
    }

    private var exitConfirmationMessage: String {
        currentURL != nil
            ? "“Save” writes over the original. “Save as New File” keeps the original untouched."
            : "Pick a location to save your new markdown file, or discard your work."
    }

    private var saveAlertBinding: Binding<Bool> {
        Binding(
            get: { saveAlert != nil },
            set: { if !$0 { saveAlert = nil } }
        )
    }

    // MARK: - Actions

    private func initializeOnFirstAppear() {
        guard !didInit else { return }
        workingText = documentText
        currentURL = sourceURL
        displayName = sourceURL?.lastPathComponent ?? "Untitled.md"

        if sourceURL == nil {
            // New document — honor the user's "New file mode" preference.
            let preference = NewFileMode(rawValue: newFileModeRaw) ?? .edit
            mode = preference == .preview ? .preview : .edit
        } else {
            mode = .preview
        }

        didInit = true
    }

    private func attemptClose() {
        if hasUnsavedChanges {
            showExitConfirmation = true
        } else {
            onClose()
        }
    }

    private func saveToSource() {
        guard let url = currentURL else { return }
        do {
            try workingText.write(to: url, atomically: true, encoding: .utf8)
            copyReferencedImagesAlongside(documentURL: url)
            onClose()
        } catch {
            saveAlert = SaveAlert(
                title: "Couldn't save",
                message: "\(error.localizedDescription)\n\nTry again, or use “Save as New File” to pick a different location."
            )
        }
    }

    /// Copies any `images/<filename>` referenced by the markdown from the app's
    /// Documents/images folder to a sibling `images/` folder next to the saved
    /// .md file — so other markdown apps can resolve the relative paths too.
    /// Silent on failure (e.g. read-only parent directory).
    private func copyReferencedImagesAlongside(documentURL: URL) {
        let pattern = #"!\[[^\]]*\]\(images/([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let nsText = workingText as NSString
        let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return }

        let parentDir = documentURL.deletingLastPathComponent()
        let destImagesDir = parentDir.appendingPathComponent("images", isDirectory: true)
        let fm = FileManager.default

        do {
            if !fm.fileExists(atPath: destImagesDir.path) {
                try fm.createDirectory(at: destImagesDir, withIntermediateDirectories: true)
            }
        } catch {
            return  // Couldn't create folder — likely read-only parent, give up.
        }

        var copied = Set<String>()
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let filename = nsText.substring(with: match.range(at: 1))
                .removingPercentEncoding ?? nsText.substring(with: match.range(at: 1))
            if copied.contains(filename) { continue }
            copied.insert(filename)

            let src = ImageStore.folderURL.appendingPathComponent(filename)
            let dst = destImagesDir.appendingPathComponent(filename)
            guard fm.fileExists(atPath: src.path) else { continue }
            if !fm.fileExists(atPath: dst.path) {
                try? fm.copyItem(at: src, to: dst)
            }
        }
    }

    private func renameTapped() {
        renameInput = baseName
        showRenameAlert = true
    }

    private func performRename() {
        let newBase = renameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newBase.isEmpty else { return }
        let safeBase = sanitize(newBase)
        let newFilename = safeBase.hasSuffix(".md") ? safeBase : "\(safeBase).md"

        if let url = currentURL {
            let newURL = url.deletingLastPathComponent().appendingPathComponent(newFilename)
            guard newURL != url else { return }
            do {
                try FileManager.default.moveItem(at: url, to: newURL)
                currentURL = newURL
                displayName = newFilename
            } catch {
                saveAlert = SaveAlert(
                    title: "Couldn't rename",
                    message: "\(error.localizedDescription)\n\nThe original file may be in a location Markflow can't write to. Try “Save to Files” to save a renamed copy."
                )
            }
        } else {
            displayName = newFilename
        }
    }

    private func sanitize(_ input: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?*\"<>|")
        return input.components(separatedBy: invalid).joined(separator: "-")
    }

    private func handleExporterResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            copyReferencedImagesAlongside(documentURL: url)
            onClose()
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == NSUserCancelledError { return }
            saveAlert = SaveAlert(
                title: "Couldn't save",
                message: "\(error.localizedDescription)\n\nTry again, or pick a different location."
            )
        }
    }
}

// MARK: - Transferable export (writes lazily, only when share is invoked)

private struct MarkdownExport: Transferable {
    let filename: String
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { export in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(export.filename)
            try export.text.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
        .suggestedFileName { $0.filename }
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
