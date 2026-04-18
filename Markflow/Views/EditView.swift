import SwiftUI
import UIKit

struct EditView: View {
    @Binding var text: String

    @AppStorage("editFontSize") private var fontSize: Double = 16
    @State private var gestureStartSize: Double = 16
    @State private var isPinching: Bool = false

    private let minFont: Double = 10
    private let maxFont: Double = 36

    var body: some View {
        MarkdownEditor(text: $text, fontSize: fontSize)
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

// MARK: - UITextView wrapper with markdown toolbar

private struct MarkdownEditor: UIViewRepresentable {
    @Binding var text: String
    let fontSize: Double

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
        tv.font = UIFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        tv.text = text
        tv.inputAccessoryView = context.coordinator.makeAccessoryView()
        context.coordinator.textView = tv
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            tv.text = text
        }
        let newFont = UIFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
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
                insertLink(tv, prefix: "![", urlPart: "](https://)")
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

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let dismissButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    private func setup() {
        autoresizingMask = [.flexibleWidth]
        frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        addSubview(divider)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        scrollView.addSubview(stack)

        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        let keyboardImage = UIImage(
            systemName: "keyboard.chevron.compact.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        )
        dismissButton.setImage(keyboardImage, for: .normal)
        dismissButton.tintColor = .label
        dismissButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        addSubview(dismissButton)

        buildButtons()

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),

            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            dismissButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            dismissButton.widthAnchor.constraint(equalToConstant: 36),
            dismissButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func dismissKeyboard() {
        self.window?.endEditing(true)
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
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = accessibility
        button.widthAnchor.constraint(equalToConstant: 38).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.onTap?(command)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }, for: .touchUpInside)
        return button
    }

    private func makeDivider() -> UIView {
        let box = UIView()
        let line = UIView()
        line.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
        line.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(line)
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 9),
            line.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            line.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            line.widthAnchor.constraint(equalToConstant: 1),
            line.heightAnchor.constraint(equalToConstant: 20)
        ])
        return box
    }

    private enum ToolbarItem {
        case button(symbol: String, accessibility: String, command: MarkdownCommand)
        case divider
    }
}
