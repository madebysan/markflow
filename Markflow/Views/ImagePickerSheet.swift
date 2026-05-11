import SwiftUI
import PhotosUI
import UIKit

struct ImagePickerSheet: UIViewControllerRepresentable {
    let onPick: (UIImage?, String?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        // .compatible delivers JPEG/PNG rather than HEIC, which WKWebView renders directly.
        config.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?, String?) -> Void

        init(onPick: @escaping (UIImage?, String?) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Do NOT call picker.dismiss(animated:) here — that calls
            // dismiss on the hosting controller, which under SwiftUI's
            // .sheet(in fullScreenCover) cascades and closes the parent
            // document. Let SwiftUI dismiss the sheet via the binding
            // when onPick fires.
            guard let result = results.first else {
                onPick(nil, nil)
                return
            }
            let provider = result.itemProvider
            let suggestedName = provider.suggestedName

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    DispatchQueue.main.async {
                        self.onPick(obj as? UIImage, suggestedName)
                    }
                }
            } else {
                onPick(nil, nil)
            }
        }
    }
}
