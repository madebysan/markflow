# How Markflow works

Editing, settings, building from source and the bundled libraries and fonts. The short version is the [README](../README.md).

## Reading and editing

Files open in read-only mode by default. Tap the floating eye/pencil glass button at the bottom to switch to Edit. Edits live in memory until you Save (writes to source), Save as New File (file picker), Share, or Export as PDF.

A floating Liquid Glass keyboard toolbar covers headings, bold, italic, strikethrough, links, images, lists, blockquotes, inline code, code blocks, and rules. Inserted images are saved beside the Markdown file. Pinch to zoom in Preview or change the editor's font size in Edit. Swipe from the left edge to dismiss an open document.

Settings (gear in Home top-right, or in any document's ••• menu) covers:

- **Appearance:** System, Light, or Dark
- **Theme:** five themes with light and dark accents
- **Text:** six fonts plus editor and preview size controls
- **Behavior:** choose whether files open in Edit or Preview
- **Recents:** the last four opened files appear on Home and can be cleared in Settings

## Building from source

Requires Xcode 26 and the iOS 26 simulator runtime.

```bash
cd Markflow
xcodegen generate
xcodebuild -project Markflow.xcodeproj -scheme Markflow \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

Or open in Xcode and press ⌘R:

```bash
open Markflow.xcodeproj
```

For a physical-device build, choose your own Apple Developer team under Signing & Capabilities, select your iPhone in Xcode's device picker and press Run.

## Acknowledgements

Rendering libraries, vendored in `Markflow/Resources/`:

- [marked](https://github.com/markedjs/marked) for markdown parsing
- [highlight.js](https://github.com/highlightjs/highlight.js) for syntax highlighting
- [Mermaid](https://github.com/mermaid-js/mermaid) for diagrams and flowcharts

Bundled fonts (SIL Open Font License), in `Markflow/Resources/fonts/`:

- [iA Writer Quattro S](https://github.com/iaolo/iA-Fonts) by iA Inc.
- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) by JetBrains
