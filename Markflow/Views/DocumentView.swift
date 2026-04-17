import SwiftUI
import UniformTypeIdentifiers

struct DocumentView: View {
    let documentText: String
    let sourceURL: URL?
    let onClose: () -> Void

    @State private var mode: Mode = .preview
    @State private var workingText: String = ""
    @State private var didInit: Bool = false

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
                    onClose()
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
    }

    private func exportedFileURL() -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(exportFileName)
        try? workingText.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}
