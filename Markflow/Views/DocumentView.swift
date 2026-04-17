import SwiftUI
import UniformTypeIdentifiers

struct DocumentView: View {
    let document: MarkdownDocument
    let sourceURL: URL?

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
        workingText != document.text
    }

    var exportFileName: String {
        let base = sourceURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
        return "\(base)-edited.md"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                ShareLink(
                    item: exportedFileURL(),
                    preview: SharePreview(exportFileName)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(hasUnsavedChanges ? Color.accentColor : Color.secondary)
                        .frame(width: 32, height: 32)
                }
                .disabled(workingText.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            switch mode {
            case .preview:
                PreviewView(markdown: workingText, baseURL: sourceURL?.deletingLastPathComponent())
            case .edit:
                EditView(text: $workingText)
            }
        }
        .onAppear {
            if !didInit {
                workingText = document.text
                didInit = true
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
