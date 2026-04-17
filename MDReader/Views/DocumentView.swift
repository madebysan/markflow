import SwiftUI

struct DocumentView: View {
    @Binding var document: MarkdownDocument
    @State private var mode: Mode = .preview

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
        Group {
            switch mode {
            case .preview:
                PreviewView(markdown: document.text)
            case .edit:
                EditView(text: $document.text)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 200)
            }
        }
    }
}
