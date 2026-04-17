# MDReader — v0 Plan

## Overview

A minimal iOS markdown reader/editor. User opens a `.md` file from the Files app, sees a segmented control at the top of the screen with **Preview** and **Edit** tabs. Preview renders the markdown (including inline images) using WKWebView + marked.js. Edit is a plain `TextEditor`. Changes save back to the original file automatically via SwiftUI's `DocumentGroup`.

## Tech Stack

- **Platform:** iOS 26, iPhone only
- **Framework:** SwiftUI + `DocumentGroup` (document-based app)
- **Language:** Swift 5.9+
- **Preview rendering:** `WKWebView` + vendored `marked.js` (local HTML resource)
- **Persistence:** none needed beyond the document itself (`DocumentGroup` handles file I/O)
- **Third-party packages:** none
- **Design:** Stock Apple HIG — system colors, SF fonts, no custom styling

## Features

1. **Open/save .md files** — `DocumentGroup` + `FileDocument` conforming type registered for `public.plain-text` + `net.daringfireball.markdown` UTIs. Gives native file browser, recent files, and automatic save/rename.
2. **Segmented tab switcher at top** — SwiftUI `Picker` with `.segmented` pickerStyle, placed inside the `NavigationStack` toolbar. Two options: `Preview`, `Edit`. Bound to a `@State var mode: Mode` enum.
3. **Preview tab (markdown + images)** — `WKWebView` wrapped in `UIViewRepresentable`. Loads an HTML template with `marked.js` embedded. Passes the markdown string via JS. Sets the `baseURL` to the document's parent directory so `![alt](image.png)` resolves against co-located image files.
4. **Edit tab (plain text editor)** — SwiftUI `TextEditor` bound to `document.text`. Standard iOS keyboard, selection, find-replace included automatically.
5. **Save on edit** — Because the `TextEditor` is bound to the document via `@Binding`, any change marks the document dirty and `DocumentGroup` saves automatically when the user backgrounds or closes the document. No explicit save button.

## Screen Inventory

| Screen | Purpose | Key state |
|--------|---------|-----------|
| **DocumentBrowser (system)** | Native file browser provided by `DocumentGroup`. User picks or creates a `.md` file. | Provided by system — no custom code. |
| **DocumentView** | The opened file. Segmented control at top, content below (Preview or Edit). | `@State var mode: Mode`, `@Binding var document: MarkdownDocument` |

Two screens total (one system-provided, one custom). Well under the 3–7 target.

## File Structure

```
md-reader/
├── project.yml                        # xcodegen config
├── plan.md                            # this file
├── MDReader/
│   ├── MDReaderApp.swift              # @main + DocumentGroup
│   ├── MarkdownDocument.swift         # FileDocument conformance
│   ├── Views/
│   │   ├── DocumentView.swift         # segmented control + content
│   │   ├── PreviewView.swift          # WKWebView wrapper
│   │   └── EditView.swift             # TextEditor wrapper
│   └── Resources/
│       └── preview.html               # HTML template + marked.js
└── .gitignore
```

No Info.plist hand-written — xcodegen's `GENERATE_INFOPLIST_FILE: YES` synthesizes it. Document type UTI registration done via `INFOPLIST_KEY_CFBundleDocumentTypes` in project.yml settings.

## Implementation Order

1. **MarkdownDocument.swift** — `FileDocument` protocol, UTI registration, init/fileWrapper
2. **preview.html** — minimal HTML with marked.js inlined or via `<script src>`, a `<div id="content">`, and a JS function `render(md)` that sets `content.innerHTML = marked.parse(md)`
3. **MDReaderApp.swift** — `DocumentGroup(newDocument:)` wiring
4. **DocumentView.swift** — segmented control + switch between PreviewView/EditView
5. **EditView.swift** — `TextEditor` bound to document.text
6. **PreviewView.swift** — `UIViewRepresentable` wrapping `WKWebView`, loads preview.html from bundle, sets baseURL to document's parent URL, calls render(md) via `evaluateJavaScript` when text changes

## Design Notes

- Stock Apple HIG: NavigationStack title shows the document filename (DocumentGroup handles this). System background colors. SF body font for text editor. No custom tint.
- Segmented control sits in `.toolbar` with `ToolbarItem(placement: .principal)` so it lives in the nav bar area.
- No dark mode customization — system-adaptive by default.

---

```yaml
run_contract:
  max_iterations: 25
  completion_promise: "V0_SWIFT_COMPLETE"
  on_stuck: defer_and_continue
  on_ambiguity: choose_simpler_option
  on_regression: revert_to_last_clean_commit
  human_intervention: never
  simulator_device: "iPhone 16e"
  ios_target: "26.0"
  visual_qa_max_passes: 2
  phase_skip:
    visual_qa: false
    polish: false
  complexity_overrides:
    open_save_files: "DocumentGroup + FileDocument conforming to .plainText + .init(importedAs: net.daringfireball.markdown)"
    tab_switcher: "SwiftUI Picker segmented style in ToolbarItem(placement: .principal)"
    preview_render: "WKWebView via UIViewRepresentable, loads preview.html from bundle, marked.js vendored as resource, baseURL = document parent directory"
    edit_view: "TextEditor bound to document.text — no custom editor component"
    save_on_edit: "No explicit save button — DocumentGroup auto-saves on background/close"
    styling: "Stock Apple HIG — no custom colors, fonts, or tint"
```
