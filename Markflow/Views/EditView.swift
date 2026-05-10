import SwiftUI
import UIKit

final class EditorBridge {
    var insertImageMarkdown: ((String, String) -> Void)?
}

struct EditView: View {
    @Binding var text: String

    @AppStorage(AppPreferences.editorFontSizeKey) private var fontSize: Double = 16
    @AppStorage(AppPreferences.documentFontKey) private var fontRaw: String = DocumentFont.mono.rawValue
    @State private var gestureStartSize: Double = 16
    @State private var isPinching: Bool = false
    @State private var bridge = EditorBridge()
    @State private var showImagePicker = false
    @State private var pickerError: String?

    private let minFont: Double = 10
    private let maxFont: Double = 36

    private var font: DocumentFont {
        DocumentFont(rawValue: fontRaw) ?? .mono
    }

    var body: some View {
        MarkdownEditor(
            text: $text,
            fontSize: fontSize,
            font: font,
            bridge: bridge,
            onImageRequest: { showImagePicker = true }
        )
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
            .sheet(isPresented: $showImagePicker) {
                ImagePickerSheet { image, suggestedName in
                    handlePicked(image: image, suggestedName: suggestedName)
                }
                .ignoresSafeArea()
            }
            .alert(
                "Couldn't add image",
                isPresented: Binding(
                    get: { pickerError != nil },
                    set: { if !$0 { pickerError = nil } }
                ),
                presenting: pickerError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
    }

    private func handlePicked(image: UIImage?, suggestedName: String?) {
        showImagePicker = false
        guard let image else { return }
        do {
            let cleanName = (suggestedName?.replacingOccurrences(of: " ", with: "-"))
                .flatMap { $0.isEmpty ? nil : $0 }
            let ref = try ImageStore.save(image: image, suggestedName: cleanName)
            let alt = suggestedName ?? ""
            bridge.insertImageMarkdown?(ref, alt)
        } catch {
            pickerError = error.localizedDescription
        }
    }
}

// MARK: - UITextView wrapper with markdown toolbar

private struct MarkdownEditor: UIViewRepresentable {
    @Binding var text: String
    let fontSize: Double
    let font: DocumentFont
    let bridge: EditorBridge
    let onImageRequest: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 16, right: 12)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.smartInsertDeleteType = .no
        tv.alwaysBounceVertical = true
        tv.font = font.uiFont(size: CGFloat(fontSize))
        tv.text = text
        tv.inputAccessoryView = context.coordinator.makeAccessoryView()
        context.coordinator.textView = tv
        bridge.insertImageMarkdown = { [weak coord = context.coordinator] ref, alt in
            coord?.insertImageMarkdown(ref: ref, alt: alt)
        }
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            tv.text = text
        }
        let newFont = font.uiFont(size: CGFloat(fontSize))
        if tv.font != newFont {
            tv.font = newFont
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownEditor
        weak var textView: UITextView?

        init(_ parent: MarkdownEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            if parent.text != textView.text {
                parent.text = textView.text
            }
        }

        // MARK: Toolbar

        func makeAccessoryView() -> UIView {
            let bar = MarkdownToolbarView()
            bar.onTap = { [weak self] command in
                self?.apply(command)
            }
            return bar
        }

        // MARK: Markdown mutations

        private func apply(_ command: MarkdownCommand) {
            guard let tv = textView else { return }
            switch command {
            case .wrap(let prefix, let suffix, let placeholder):
                wrap(tv, prefix: prefix, suffix: suffix, placeholder: placeholder)
            case .linePrefix(let prefix):
                addLinePrefix(tv, prefix: prefix)
            case .link:
                insertLink(tv, prefix: "[", urlPart: "](https://)")
            case .image:
                parent.onImageRequest()
            case .rule:
                insertBlock(tv, text: "\n\n---\n\n", cursorOffset: nil)
            case .codeBlock:
                insertBlock(
                    tv,
                    text: "\n```\n\n```\n",
                    cursorOffset: 5 // place cursor after "\n```\n"
                )
            }
        }

        func insertImageMarkdown(ref: String, alt: String) {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            let markdown = "![\(alt)](\(ref))"
            replace(tv, range: range, with: markdown)
            setCursor(tv, to: range.location + (markdown as NSString).length)
        }

        private func wrap(_ tv: UITextView, prefix: String, suffix: String, placeholder: String) {
            let range = tv.selectedRange
            let nsText = (tv.text ?? "") as NSString
            let hasSelection = range.length > 0
            let inner = hasSelection ? nsText.substring(with: range) : placeholder
            let replacement = prefix + inner + suffix
            replace(tv, range: range, with: replacement)
            let newCursor: Int
            if hasSelection {
                newCursor = range.location + replacement.utf16.count
            } else {
                newCursor = range.location + prefix.utf16.count + placeholder.utf16.count
            }
            setCursor(tv, to: newCursor, selectionLength: hasSelection ? 0 : (placeholder.isEmpty ? 0 : placeholder.utf16.count), hasPlaceholder: !hasSelection && !placeholder.isEmpty, placeholderStart: range.location + prefix.utf16.count)
        }

        private func addLinePrefix(_ tv: UITextView, prefix: String) {
            let range = tv.selectedRange
            let nsText = (tv.text ?? "") as NSString
            // Find start of current line
            var lineStart = range.location
            while lineStart > 0 {
                let prev = nsText.substring(with: NSRange(location: lineStart - 1, length: 1))
                if prev == "\n" { break }
                lineStart -= 1
            }
            // Don't duplicate prefix
            let remaining = nsText.length - lineStart
            let peekLen = min(prefix.utf16.count, remaining)
            let peek = peekLen > 0 ? nsText.substring(with: NSRange(location: lineStart, length: peekLen)) : ""
            if peek == prefix {
                // Remove it (toggle off)
                replace(tv, range: NSRange(location: lineStart, length: peekLen), with: "")
                setCursor(tv, to: max(lineStart, range.location - peekLen))
            } else {
                replace(tv, range: NSRange(location: lineStart, length: 0), with: prefix)
                setCursor(tv, to: range.location + prefix.utf16.count)
            }
        }

        private func insertLink(_ tv: UITextView, prefix: String, urlPart: String) {
            let range = tv.selectedRange
            let nsText = (tv.text ?? "") as NSString
            let hasSelection = range.length > 0
            let inner = hasSelection ? nsText.substring(with: range) : "text"
            let replacement = prefix + inner + urlPart
            replace(tv, range: range, with: replacement)
            // Place cursor on "https://" so user can replace it by typing
            let urlStart = range.location + prefix.utf16.count + inner.utf16.count + 2 // ](
            let urlLength = ("https://" as NSString).length
            tv.selectedRange = NSRange(location: urlStart, length: urlLength)
        }

        private func insertBlock(_ tv: UITextView, text: String, cursorOffset: Int?) {
            let range = tv.selectedRange
            replace(tv, range: range, with: text)
            if let offset = cursorOffset {
                setCursor(tv, to: range.location + offset)
            } else {
                setCursor(tv, to: range.location + text.utf16.count)
            }
        }

        private func replace(_ tv: UITextView, range: NSRange, with string: String) {
            guard let start = tv.position(from: tv.beginningOfDocument, offset: range.location),
                  let end = tv.position(from: start, offset: range.length),
                  let textRange = tv.textRange(from: start, to: end) else {
                return
            }
            tv.replace(textRange, withText: string)
            // Manually sync binding — replace() doesn't always trigger textViewDidChange on iOS.
            parent.text = tv.text
        }

        private func setCursor(_ tv: UITextView, to location: Int, selectionLength: Int = 0, hasPlaceholder: Bool = false, placeholderStart: Int = 0) {
            let total = (tv.text as NSString).length
            let clamped = min(max(location, 0), total)
            if hasPlaceholder {
                let len = min(selectionLength, max(0, total - placeholderStart))
                tv.selectedRange = NSRange(location: placeholderStart, length: len)
            } else {
                tv.selectedRange = NSRange(location: clamped, length: 0)
            }
        }
    }
}

// MARK: - Markdown commands

private enum MarkdownCommand {
    case wrap(prefix: String, suffix: String, placeholder: String)
    case linePrefix(String)
    case link
    case image
    case rule
    case codeBlock
}

// MARK: - Toolbar view (UIKit, used as inputAccessoryView)

private final class MarkdownToolbarView: UIView {
    var onTap: ((MarkdownCommand) -> Void)?

    private let capsule = UIView()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let dismissDivider = UIView()
    private let dismissButton = UIButton(type: .system)

    private let toolbarHeight: CGFloat = 60
    private let capsuleHeight: CGFloat = 44
    private let horizontalInset: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: toolbarHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        capsule.layer.cornerRadius = capsuleHeight / 2
    }

    private func setup() {
        autoresizingMask = [.flexibleWidth]
        backgroundColor = .clear
        frame = CGRect(x: 0, y: 0, width: 0, height: toolbarHeight)

        capsule.translatesAutoresizingMaskIntoConstraints = false
        capsule.layer.cornerCurve = .continuous
        capsule.clipsToBounds = true
        capsule.layer.borderWidth = 0.5
        capsule.layer.borderColor = UIColor.label.withAlphaComponent(0.08).cgColor
        addSubview(capsule)

        blur.translatesAutoresizingMaskIntoConstraints = false
        capsule.addSubview(blur)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        capsule.addSubview(scrollView)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
        scrollView.addSubview(stack)

        dismissDivider.translatesAutoresizingMaskIntoConstraints = false
        dismissDivider.backgroundColor = UIColor.separator.withAlphaComponent(0.45)
        capsule.addSubview(dismissDivider)

        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        let keyboardImage = UIImage(
            systemName: "keyboard.chevron.compact.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        )
        dismissButton.setImage(keyboardImage, for: .normal)
        dismissButton.tintColor = .label
        dismissButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        capsule.addSubview(dismissButton)

        buildButtons()

        NSLayoutConstraint.activate([
            capsule.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
            capsule.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
            capsule.centerYAnchor.constraint(equalTo: centerYAnchor),
            capsule.heightAnchor.constraint(equalToConstant: capsuleHeight),

            blur.topAnchor.constraint(equalTo: capsule.topAnchor),
            blur.leadingAnchor.constraint(equalTo: capsule.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: capsule.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: capsule.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: capsule.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: capsule.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: dismissDivider.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: capsule.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            dismissDivider.widthAnchor.constraint(equalToConstant: 0.5),
            dismissDivider.heightAnchor.constraint(equalToConstant: 24),
            dismissDivider.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
            dismissDivider.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -2),

            dismissButton.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -4),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func dismissKeyboard() {
        // self.window points at the keyboard's UIInputWindow when this view
        // is used as inputAccessoryView, so endEditing(true) on it does
        // nothing. Walk the responder chain instead.
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private func buildButtons() {
        let items: [ToolbarItem] = [
            .button(symbol: "number", accessibility: "Heading 1",
                    command: .linePrefix("# ")),
            .button(symbol: "number.square", accessibility: "Heading 2",
                    command: .linePrefix("## ")),
            .divider,
            .button(symbol: "bold", accessibility: "Bold",
                    command: .wrap(prefix: "**", suffix: "**", placeholder: "text")),
            .button(symbol: "italic", accessibility: "Italic",
                    command: .wrap(prefix: "*", suffix: "*", placeholder: "text")),
            .button(symbol: "strikethrough", accessibility: "Strikethrough",
                    command: .wrap(prefix: "~~", suffix: "~~", placeholder: "text")),
            .divider,
            .button(symbol: "link", accessibility: "Link", command: .link),
            .button(symbol: "photo", accessibility: "Image", command: .image),
            .divider,
            .button(symbol: "list.bullet", accessibility: "Bullet list",
                    command: .linePrefix("- ")),
            .button(symbol: "list.number", accessibility: "Numbered list",
                    command: .linePrefix("1. ")),
            .button(symbol: "checklist", accessibility: "Task list",
                    command: .linePrefix("- [ ] ")),
            .divider,
            .button(symbol: "quote.opening", accessibility: "Quote",
                    command: .linePrefix("> ")),
            .button(symbol: "curlybraces", accessibility: "Inline code",
                    command: .wrap(prefix: "`", suffix: "`", placeholder: "code")),
            .button(symbol: "curlybraces.square", accessibility: "Code block",
                    command: .codeBlock),
            .button(symbol: "minus", accessibility: "Horizontal rule",
                    command: .rule)
        ]

        for item in items {
            switch item {
            case .button(let symbol, let a11y, let command):
                stack.addArrangedSubview(makeButton(symbol: symbol, accessibility: a11y, command: command))
            case .divider:
                stack.addArrangedSubview(makeDivider())
            }
        }
    }

    private func makeButton(symbol: String, accessibility: String, command: MarkdownCommand) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = accessibility
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.onTap?(command)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }, for: .touchUpInside)
        return button
    }

    private func makeDivider() -> UIView {
        let box = UIView()
        let line = UIView()
        line.backgroundColor = UIColor.separator.withAlphaComponent(0.45)
        line.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(line)
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 10),
            line.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            line.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            line.widthAnchor.constraint(equalToConstant: 1),
            line.heightAnchor.constraint(equalToConstant: 22)
        ])
        return box
    }

    private enum ToolbarItem {
        case button(symbol: String, accessibility: String, command: MarkdownCommand)
        case divider
    }
}
