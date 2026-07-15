<p><img src="docs/icon.png" width="128" height="128" alt="Markflow icon"></p>

<h1>Markflow</h1>

<p>Open Markdown files on your iPhone as rendered documents.<br>
Read, edit, save, or share without moving the file into another system.</p>

<p><strong>Version 0.2.0</strong> · iOS 26 · SwiftUI</p>

<p>
  <img src="https://img.shields.io/badge/Swift-f05138" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-0066cc" alt="SwiftUI">
  <img src="https://img.shields.io/badge/iOS-000000" alt="iOS">
</p>

<p>
  <a href="https://apps.apple.com/us/app/markflow-markdown-reader/id6763440990"><img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="50"></a>
</p>

![Markflow app screenshots](docs/screenshots/hero.png)

Markflow is a native markdown reader and editor for iOS 26. Tap any `.md` file in Files, Mail, or Safari and it opens rendered: code blocks, mermaid diagrams, tables, inline images. Files open read-only by default and edits live in memory until you explicitly choose Save, Save as New File, or Share.

## How it works

Files open in read-only mode by default. Tap the floating eye/pencil glass button at the bottom to switch to Edit. Edits live in memory until you Save (writes to source), Save as New File (file picker), Share, or Export as PDF.

A floating Liquid Glass keyboard toolbar covers headings, bold, italic, strikethrough, links, images, lists, blockquotes, inline code, code blocks, and rules. Inserted images are saved beside the Markdown file. Pinch to zoom in Preview or change the editor's font size in Edit. Swipe from the left edge to dismiss an open document.

Settings (gear in Home top-right, or in any document's ••• menu) covers:

- **Appearance:** System, Light, or Dark
- **Theme:** five themes with light and dark accents
- **Text:** six fonts plus editor and preview size controls
- **Behavior:** choose whether files open in Edit or Preview
- **Recents:** the last four opened files appear on Home and can be cleared in Settings

## Build from source

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

For a physical-device build, the bundle is signed under Team `QAMM2A6WRQ` (Apple Developer Program). Select your iPhone in Xcode's device picker and hit Run.

## Known limitations

- Relative image paths in markdown (`![](image.png)`) don't resolve. Use absolute URLs.
- No "Recents" list on the home screen (dropped when we replaced `DocumentGroup`).

## Support

User support: see [docs/support.md](docs/support.md) or email [hi@santiagoalonso.com](mailto:hi@santiagoalonso.com).

Bug reports and feature requests: [open an issue](https://github.com/madebysan/markflow/issues).

## Acknowledgements

Rendering libraries, vendored in `Markflow/Resources/`:

- [marked](https://github.com/markedjs/marked) for markdown parsing
- [highlight.js](https://github.com/highlightjs/highlight.js) for syntax highlighting
- [Mermaid](https://github.com/mermaid-js/mermaid) for diagrams and flowcharts

Bundled fonts (SIL Open Font License), in `Markflow/Resources/fonts/`:

- [iA Writer Quattro S](https://github.com/iaolo/iA-Fonts) by iA Inc.
- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) by JetBrains

## License

[MIT](LICENSE)

Made by [santiagoalonso.com](https://santiagoalonso.com)
