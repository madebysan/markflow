import SwiftUI

struct EditView: View {
    @Binding var text: String

    @AppStorage("editFontSize") private var fontSize: Double = 16
    @State private var gestureStartSize: Double = 16
    @State private var isPinching: Bool = false

    private let minFont: Double = 10
    private let maxFont: Double = 36

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: fontSize, design: .monospaced))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        if !isPinching {
                            isPinching = true
                            gestureStartSize = fontSize
                        }
                        let proposed = gestureStartSize * value.magnification
                        fontSize = min(max(proposed, minFont), maxFont)
                    }
                    .onEnded { _ in
                        isPinching = false
                    }
            )
    }
}
