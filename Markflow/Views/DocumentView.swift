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
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { m in
                    Text(m.label).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            switch mode {
            case .preview:
                PreviewView(markdown: document.text)
            case .edit:
                EditView(text: $document.text)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }
}
