<p><img src="docs/icon.png" width="128" height="128" alt="Markflow icon"></p>

<h1>Markflow</h1>

<p>Open Markdown files on your iPhone as rendered documents.<br>
Read, edit, save or share them without moving the file into another app.</p>

<p><strong>Version 0.2.0</strong> · iOS 26+</p>

<p>
  <img src="https://img.shields.io/badge/Swift-f05138" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-0066cc" alt="SwiftUI">
  <img src="https://img.shields.io/badge/iOS-000000" alt="iOS">
</p>

<p>
  <a href="https://apps.apple.com/us/app/markflow-markdown-reader/id6763440990"><img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="50"></a>
</p>

![Markflow showing its home screen, a rendered document and the editor with its formatting toolbar](docs/screenshots/hero.png)

Tap a `.md` file in Files, Mail or Safari and Markflow opens it rendered, for anyone who keeps notes or docs in Markdown and reads them on the phone.

- Code blocks, Mermaid diagrams, tables and images render as you'd expect.
- Files open read-only, so nothing changes until you choose Save.
- Edits write back to the original file, or to a new one.

## How it works

Tap the floating eye and pencil button to switch between Preview and Edit. Edits stay in memory until you Save, Save as New File, Share or Export as PDF. In Edit, a toolbar covers headings, emphasis, links, images, lists, quotes and code; images you insert are saved beside the Markdown file. Settings has five themes, six fonts, light and dark appearance, and whether files open in Edit or Preview. The full tour is in [docs/how-it-works.md](docs/how-it-works.md).

## Limits

Images stored next to a file you open from Files or another app (`![](image.png)`) don't display yet. Images you insert with Markflow, and images with web addresses, do.

## Install

Get it on the [App Store](https://apps.apple.com/us/app/markflow-markdown-reader/id6763440990). To build it, you need Xcode 26 and [XcodeGen](https://github.com/yonaskolb/XcodeGen): run `xcodegen generate` in `Markflow/` and open the project. Support is in [docs/support.md](docs/support.md), or email [hi@santiagoalonso.com](mailto:hi@santiagoalonso.com).

---

[MIT](LICENSE). Markflow bundles [marked](https://github.com/markedjs/marked), [highlight.js](https://github.com/highlightjs/highlight.js) and [Mermaid](https://github.com/mermaid-js/mermaid), and the [iA Writer Quattro](https://github.com/iaolo/iA-Fonts) and [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) fonts under the SIL Open Font License.

Made by [santiagoalonso.com](https://santiagoalonso.com)
