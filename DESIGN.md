# Markflow — Design

Living design authority for Markflow. Describes visual identity, UI patterns, and decisions as they exist in code. Updated alongside the code, not as a locked spec.

## Atmosphere

Calm, writerly, brand-forward. Not a utility app — it's the *place* for markdown on iOS. Purple/indigo brand heritage from the icon carries into the home screen; document reading is stock Apple HIG so the content wins. As of v0.2.0, accent color is user-controlled via Theme picker — Indigo is the default but no longer hardcoded.

## Colors

### Theme system (v0.2.0+)

The accent color is theme-driven, not hardcoded. 5 named themes, each with separate light + dark hex values that resolve via `UIColor` `dynamicProvider`:

| Theme | Light | Dark |
|---|---|---|
| Indigo (default) | `#7869E4` | `#9489F3` |
| Forest | `#2C9F65` | `#4FBE85` |
| Sunset | `#E16A3D` | `#F39163` |
| Ocean | `#2A8DBE` | `#5BB0DC` |
| Graphite | `#4F5560` | `#A0A6B0` |

Defined in `AppThemeCatalog` (`Markflow/AccentColor.swift`). Persisted via `@AppStorage("themeID")`. Applied via `.tint(theme.accentColor)` at WindowGroup root AND on every sheet's root + on Forms (sheets cache env at present time, and pushed Picker sub-lists need direct Form-level tint to update live).

The theme accent drives: Home Browse button, brand icon glow shadow, Settings checkmarks + Done button, document toolbar tints, mode toggle selected state. Replaced the old hardcoded `primaryGradient` purple.

### Home gradient

| State | Colors |
|-------|--------|
| Light | `#FAFAFC` → `#EFEDF7` (subtle lavender wash, top-leading → bottom-trailing) |
| Dark  | `#1A1A21` → `#241F2E` (soft slate-indigo, top-leading → bottom-trailing) |

Tuned 2026-05-10 to be less saturated — original deep purples felt too jarring between modes. Background is theme-agnostic (doesn't shift with theme picker — only with light/dark mode).

### Preview (HTML)

Light and dark themes defined in `preview.html` via CSS `prefers-color-scheme`:

| Token | Light | Dark |
|-------|-------|------|
| `--fg` | `#1c1c1e` | `#f2f2f7` |
| `--bg` | `#ffffff` | `#000000` |
| `--muted` | `#6e6e73` | `#8e8e93` |
| `--rule` | `#e5e5ea` | `#2c2c2e` |
| `--code-bg` | `#f6f8fa` | `#161b22` |
| `--link` | `#007aff` | `#0a84ff` |
| `--checkbox-checked` | `#34c759` | `#30d158` |

These align with iOS system colors.

## Typography

### Chrome (fixed)

- **Brand title** — 42pt bold, tracking -0.8, SF Pro
- **Tagline** — 17pt regular, line-height ~1.2, `.primary.opacity(0.72)` for contrast
- **Button label** — 18pt semibold
- **Credit** — 13pt medium, `.primary.opacity(0.5)` (adapts: near-black in light mode, near-white in dark). `.tint` on the `Link` is pinned to the same value so iOS's accent color doesn't bleed through.
- **Preview headings** — 28/22/19pt bold (H1/H2/H3)
- **Preview code** — 14–15pt SF Mono / Menlo (forced; document font picker doesn't override code blocks)

### Document body (user-controlled, v0.2.0+)

User picks 1 of 6 fonts via Settings → Text → Font. Applies to both Editor (`UIFont`) and Preview (CSS `--body-font` injected via JS):

| Option | UIFont source | CSS family | Distinguishing trait |
|---|---|---|---|
| System | `.systemFont(ofSize:)` | `-apple-system, system-ui` | SF Pro, default sans |
| Rounded | `preferredFontDescriptor(.body).withDesign(.rounded)` | `ui-rounded` | SF Pro Rounded — softer terminals |
| Charter | `UIFont(name: "Charter-Roman")` | `Charter, ui-serif` | iOS-bundled reading serif |
| Monospace | `.monospacedSystemFont(ofSize:)` | `ui-monospace, "SF Mono"` | SF Mono |
| iA Writer | `UIFont(name: "iAWriterQuattroS-Regular")` | `'iAWriterQuattroS-Regular'` | Bundled, distinctive writer's font |
| JetBrains | `UIFont(name: "JetBrainsMono-Regular")` | `'JetBrainsMono-Regular'` | Bundled, code-y mono with ligatures |

**Editor font size** — slider 12–24pt, `@AppStorage("editFontSize")`, also written by pinch-to-zoom (`MagnifyGesture`).

**Preview font size** — separate slider 12–24pt, `@AppStorage("previewFontSize")`, injected as CSS `--body-font-size`.

Code blocks intentionally don't follow the font setting — code stays in mono regardless. Headings inherit the body font (so "Charter" gets serif headings, "iA Writer" gets iA headings).

## Shape language

- **Corner radius** — 18pt on home buttons, 28pt on app icon display, `continuous` style everywhere
- **Icon display** — 128×128pt with 28pt continuous rounded rect clip + tinted shadow (brand shadow, 24pt blur, y:12)
- **Button height** — 56pt
- **Nav bar toolbar items** — iOS 26 Liquid Glass pills (native, no custom styling)

## Spacing

- **Home stack** — 20pt between icon and title group, 8pt between title and tagline, 12pt between primary/secondary CTAs
- **Home padding** — 24pt horizontal for action stack, 32pt bottom for credit, 40pt min top spacer
- **Preview content** — 20pt horizontal / 60pt bottom inside WKWebView

## Patterns

### Markdown toolbar (Edit mode) — v0.2.0 floating glass

Keyboard-accessory bar, 60pt total height with a 44pt-tall capsule inset 12pt from screen edges. The capsule is `UIVisualEffectView` (`.systemUltraThinMaterial`) with 22pt corner radius, 0.5pt label-tinted border, scrollable button stack on the left, hairline divider, dismiss button on the right.

Buttons are 42×40pt SF Symbols (`pointSize: 17, weight: .medium`), tinted `.label`, with 1pt-wide separator bars between logical groups (headings / emphasis / link+image / lists / blocks). Light haptic (`UIImpactFeedbackGenerator.light`) fires on every action.

**Important**: the dismiss button uses `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...)` walking the responder chain — `self.window?.endEditing(true)` doesn't work because `inputAccessoryView`'s window is the keyboard's `UIInputWindow`, not the main window.

Action semantics:

- **Wrap** commands (bold/italic/strikethrough/inline code) — wrap selection with prefix/suffix, or insert `prefix + placeholder + suffix` with placeholder pre-selected when nothing is selected.
- **Line-prefix** commands (headings, lists, quote) — inserted at the start of the current line. Second tap on the same prefix toggles it off.
- **Link** — `[text](https://)` with `https://` pre-selected so the user types over it.
- **Image** — fires `onImageRequest` callback up to SwiftUI parent which presents PHPicker; selected image saves to `Documents/images/` and inserts `![alt](images/UUID-name.ext)` at cursor via `EditorBridge` closure.

### Entrance animation (Home)

Brand stack + action stack fade in (`opacity 0→1`) with a 14–18pt slide-up, 0.5s easeOut, on first appear. Credit link fades in alongside. No repeating animations on home — static `LinearGradient` background only.

### Primary CTA

Full-width gradient button, 56pt tall, 18pt corner radius, brand gradient fill, white text + icon (18pt semibold), tinted drop shadow matching brand gradient. Used for: Browse (main Markflow action). Signals: "do this — it's the point of the app."

### Secondary CTA (white card)

Full-width solid-white button, 56pt tall, 18pt corner radius, `Color.white` fill, soft black 8% drop shadow (10pt blur, y:4), black text + icon. Used for: Create and Welcome to Markflow. Both secondary CTAs share the identical `whiteLabel(icon:title:)` helper — different icons and labels, same surface. Signals: "available action, less prominent than Browse." Works equally in light and dark mode.

### Nav bar items (iOS 26)

Close / picker / share all sit in `ToolbarItem` placements. iOS 26's Liquid Glass renders them as glass pills automatically — no custom styling. Segmented Picker in `.principal`, Share in `.topBarTrailing`, Close chevron in `.topBarLeading`.

### Preview / Edit toggle (v0.2.0 single-icon glass)

Floating glass circle, 48×48pt, `.ultraThinMaterial` background with 0.5pt label-tinted border, 14pt-blur shadow at `y:6`. Lives in `.overlay(alignment: .bottom)` (NOT `.safeAreaInset` — that reserves vertical space and consumed too much of the document area).

Single SF Symbol that swaps based on current mode using iOS 17+'s `.symbolEffect(.replace)` for a smooth animated transition:

- In Preview → shows **`pencil`** (tap to switch to Edit)
- In Edit → shows **`eye`** (tap to switch to Preview)

The icon shows the *destination* (where you'll go), matching iOS conventions. Single tap target, smallest possible visual footprint.

Mode state is per-document, not persisted. New documents (no `sourceURL`) honor the user's "New files open in" setting (Edit by default). Existing documents always open in Preview.

### Filename in nav bar

Centered title shows the current `displayName` (defaults to `sourceURL.lastPathComponent` or `"Untitled.md"`). Editable via Options → Rename, which presents a TextField alert and attempts FS rename of the source URL in place.

### Options menu (`••• ` topBarTrailing)

`Menu` with five items + divider:

1. **Rename** — TextField alert, FS `moveItem(at:to:)` on source URL parent. Falls back to error alert with "Save as New File" hint if read-only.
2. **Save to Files** — existing `.fileExporter` with `MarkdownFileDocument`.
3. **Share** — `ShareLink` with `MarkdownExport` Transferable (lazy temp-file write).
4. **Export as PDF** — runs `PDFExporter` (off-screen WKWebView + `createPDF`), then presents `UIActivityViewController` via `ShareSheet` wrapper. Disabled while exporting (`exportingPDF` state).
5. *(divider)*
6. **Settings** — opens `SettingsView` as a sheet from within the document.

### Image insertion + portability (v0.2.0)

When the toolbar image button is tapped:

1. PHPicker sheet presents (`PHPickerConfiguration.preferredAssetRepresentationMode = .compatible` so HEIC delivers as JPEG).
2. Picker delegate **does not** call `picker.dismiss(animated:)` — that cascades through SwiftUI sheet → fullScreenCover and dismisses the parent document. SwiftUI dismisses via the `showImagePicker` binding instead.
3. Image saved to `Documents/images/UUID-name.{jpg|png}` (PNG when alpha present, JPEG q=0.9 otherwise) via `ImageStore`.
4. Markdown `![alt](images/UUID-name.ext)` inserted at cursor via `EditorBridge` closure → `MarkdownEditor.Coordinator.insertImageMarkdown`.
5. Preview renders via `preview.js` `rewriteImageSources()` which prepends `window.imageBasePath` (set to `file:///<Documents>/`).
6. On Save (write to source) or Save As, `copyReferencedImagesAlongside(documentURL:)` scans markdown for `images/...` refs and copies them to a sibling `images/` folder next to the .md — so other markdown apps resolve the same relative paths.

Tradeoff: each image lives in two places (Markflow sandbox + sibling). Worth it: keeps Preview fast AND .md is portable.

### Recents on Home (v0.2.0)

Shows up to **4 most recently opened files** above Browse/Create when `RecentsStore.shared.entries` is non-empty. Welcome to Markflow button auto-hides when recents exist.

Each row: `doc.text` icon, filename + relative time (`RelativeDateTimeFormatter.abbreviated`), chevron. `.ultraThinMaterial` background, 14pt corner radius, hairline border. Tap resolves the security-scoped bookmark and opens.

`RecentsStore` is `@Observable`, persists `[RecentEntry]` (UUID id + displayName + bookmarkData + lastOpened) as JSON in `UserDefaults`. Stale entries (file moved/deleted) are silently pruned on resolve failure. Capped at 4 in storage AND display.

### Settings sheet

Presented as a sheet from Home's gear icon (top-right) OR from any document's Options menu. `Form` with sections:

1. **Appearance** — segmented Picker: System / Light / Dark
2. **Theme** — list of 5 themes with color swatch + checkmark on selected
3. **Text** — Font NavigationLink (custom `FontPickerList` because SwiftUI default `Picker` ignores per-row `.font()`), Editor size slider, Preview size slider
4. **Behavior** — "New files open in" Picker (Edit / Preview)
5. **Recents** — Clear recents button (destructive, confirmation dialog) — shown only when recents non-empty
6. **About** — Link rows to santiagoalonso.com, Support, Privacy

`.preferredColorScheme()` and `.tint()` applied directly on the SettingsView root because sheets cache the presenting view's environment at present time — applying only at WindowGroup level doesn't switch live.

### Swipe-from-left close gesture

`.simultaneousGesture(DragGesture)` with `.global` coordinate space. Origin must be `x < 24pt` (true left edge). Document follows finger via `.offset(x: swipeOffset)` during drag, snaps back with `.spring(response: 0.28)` on release if translation < 90pt, calls `attemptClose()` past threshold.

Coexists with WKWebView/UITextView gestures via `.simultaneousGesture`. Edge-only origin prevents false positives from regular content interactions.

### Unsaved-changes confirmation

Triggered when the back chevron is tapped with `workingText != documentText`. Uses `.confirmationDialog` with these actions:

- **Save** — overwrites the source file. Only offered when `sourceURL != nil` (files opened from share sheet or Files). Dismisses the document on success.
- **Save as New File…** — presents `.fileExporter` with `MarkdownFileDocument`. Default filename is `<source-base>-copy` or `Untitled` for new documents. Dismisses on success; `NSUserCancelledError` on cancel is silently ignored.
- **Discard Changes** — destructive, red. Drops edits and returns to home.
- **Cancel** — stays in the editor.

Save errors surface via a separate `.alert`. Security-scoped access to the source URL is held for the entire document session (started in `HomeView.open`, released in `onClose`) so Save can write back without re-requesting permission.

## Shared components

### Views
- `HomeView` — home screen with Settings entry, Recents, Browse/Create (`Markflow/Views/HomeView.swift`)
- `SettingsView` — Form-based settings sheet (`Markflow/Views/SettingsView.swift`)
- `FontPickerList` — custom NavigationLink-driven font picker (private in SettingsView.swift)
- `DocumentContainer` — private wrapper inside HomeView.swift, provides NavigationStack
- `DocumentView` — document reader/editor root (`Markflow/Views/DocumentView.swift`)
- `PreviewView` — `UIViewRepresentable` wrapping WKWebView (`Markflow/Views/PreviewView.swift`)
- `EditView` — `UITextView` wrapper with markdown toolbar, magnification gesture, image picker plumbing (`Markflow/Views/EditView.swift`)
- `MarkdownToolbarView` — UIKit `inputAccessoryView`, floating glass capsule (private in EditView.swift)
- `ImagePickerSheet` — `UIViewControllerRepresentable` over `PHPickerViewController` (`Markflow/Views/ImagePickerSheet.swift`)
- `ShareSheet` — `UIViewControllerRepresentable` over `UIActivityViewController` (`Markflow/Views/ShareSheet.swift`)

### Models / stores
- `OpenedDocument` — `id`, `text`, `sourceURL?` (defined in HomeView.swift)
- `EditorBridge` — class holding closure `insertImageMarkdown: ((String, String) -> Void)?` to bridge SwiftUI image-pick callback into the UIKit Coordinator (defined in EditView.swift)
- `RecentEntry` / `RecentsStore` — `@Observable` singleton, bookmark-based recent files (`Markflow/RecentsStore.swift`)
- `IdentifiableURL` — wraps URL for `.sheet(item:)` (in ShareSheet.swift)

### Helpers
- `AppTheme` / `AppThemeCatalog` — theme system (`Markflow/AccentColor.swift`)
- `AppearancePreference` / `NewFileMode` / `DocumentFont` — settings enums (in AccentColor.swift)
- `AppPreferences` — `@AppStorage` key constants (in AccentColor.swift)
- `HexColor` — hex ↔ Color conversions (in AccentColor.swift)
- `ImageStore` — saves UIImage to `Documents/images/` with UUID prefix, returns markdown ref (`Markflow/ImageStore.swift`)
- `PreviewAssets` — mirrors bundled preview HTML/JS/CSS/fonts to `Documents/preview/` on launch, version-keyed (`Markflow/PreviewAssets.swift`)
- `PDFExporter` — off-screen WKWebView + `WKScriptMessageHandler` + `createPDF` for PDF export (`Markflow/PDFExporter.swift`)

## Decisions

- **Read-only by default, explicit export only.** (2026-04-17) Markdown files often belong to someone else — silently overwriting the source on edit is wrong. Edits live in memory, Share sheet exports a copy.
- **Custom home replaces DocumentGroup launch browser.** (2026-04-17) Markflow is a reader; Browse should be primary, not Create. DocumentGroup's default order is wrong for this app.
- **WKWebView + vendored JS for preview, not native AttributedString.** (2026-04-17) Only path to rendering inline images, tables, mermaid diagrams. Native markdown APIs don't support any of these.
- **Mermaid diagrams included despite 3 MB cost — but lazy-loaded.** (2026-04-18) Real documents lean on flowcharts; losing them would be worse than the binary size hit. Fetching only when a ` ```mermaid ` block is present keeps first-render fast for the 95% of files that don't need diagrams.
- **iOS 26 target (not 17 or 18).** (2026-04-17) New install, no legacy users, lets us use Liquid Glass toolbar styling for free.
- **iPhone only, no iPad.** (2026-04-17) Keeps layout simple for v0. Universal target can be a v1 move.
- **Close chevron, not "Done" text.** (2026-04-17) iOS 26 pattern; chevron reads as "back to home" better than modal-dismiss wording.
- **Two button styles on home, not three.** (2026-04-18) Tried gradient + material + white — read as "three different buttons" rather than a hierarchy. Collapsed to gradient (Browse) + white card (Create, Welcome). Three CTAs, two visual treatments.
- **No ambient orbs, no repeating animations.** (2026-04-18) Animated radial gradients behind `.regularMaterial` buttons forced the GPU to re-blur every frame — `WebProcessProxy::didBecomeUnresponsive` caliber slow. Static `LinearGradient` background is enough; entrance animation is one-shot.
- **WebKit prewarm on app launch.** (2026-04-18) `WebViewPrewarmer.shared.prewarm()` in `MarkflowApp.init()` spawns WKWebView's WebContent/GPU/Networking processes in the background (~2–3s each) so first document open doesn't pay the cold-start tax.
- **Content-Security-Policy on preview.** (2026-04-18) User-authored `.md` can contain raw HTML that marked passes through. CSP `script-src 'self'; connect-src 'none'` blocks any injected script from executing or exfiltrating. Required extracting init JS from inline to `preview.js`.
- **Theme accent over single brand color.** (2026-05-10) User feedback: a free-form ColorPicker felt overcustom. Replaced with 5 curated themes, each tuned for both light and dark. Less choice, better defaults. `UIColor` `dynamicProvider` resolves the right hex per `userInterfaceStyle` so a single `accentColor` property adapts.
- **Custom NavigationLink for font picker, not Picker.** (2026-05-10) SwiftUI default `Picker` in Form context discards per-row `.font()` modifiers in its pushed sub-list. To show each font option in its own font, built `FontPickerList` as a NavigationLink + custom Form with Button rows.
- **Off-screen WKWebView for PDF export, not native rendering.** (2026-05-10) Reuses the entire preview rendering pipeline (marked + highlight + mermaid + selected font + CSS) without duplicating logic. `WKScriptMessageHandler` ("renderDone") notifies when JS render completes, then `createPDF` writes US Letter pages to temp file.
- **Preview assets relocated to Documents.** (2026-05-10) `WKWebView.loadFileURL(allowingReadAccessTo:)` only takes ONE root path. User-saved images live in `Documents/images/`, so preview.html (and its sibling JS/CSS/fonts) had to move under Documents too. `PreviewAssets.ensure()` mirrors them on launch when bundle build version changes.
- **Image storage: sandbox + sibling-on-Save, not base64 or single-location.** (2026-05-10) Images saved to `Documents/images/` for fast preview; on Save (or Save As), copied to a sibling `images/` folder next to the .md so other markdown apps resolve the relative paths. Each image lives in two places — accepted tradeoff to keep both Preview fast AND .md portable.
- **Bundled iA Writer + JetBrains Mono.** (2026-05-10) System fonts alone (System, Rounded, Charter, SF Mono) didn't have enough character. Two open source fonts (~785 KB total) bundled and registered via `UIAppFonts` + mirrored to Documents/preview/ for `@font-face` consumption. Both SIL OFL — free for commercial use, attribution in README.
- **Preview/Edit as a single floating glass icon, not a segmented control.** (2026-05-10) Original was a 200pt segmented Picker in the nav bar's principal slot, then a 200pt segmented control in the bottom safe-area inset, then a 2-icon glass capsule. Final form: single 48pt circle showing only the *destination* icon (eye when in Edit, pencil when in Preview). Smallest footprint, least chrome.
- **Sheet env doesn't update live.** (2026-05-10) `.preferredColorScheme()` and `.tint()` applied at WindowGroup root don't propagate live into a presented sheet — sheets cache the env at present time. Must apply both modifiers directly on the sheet's root for live appearance/theme switching.

## Anti-patterns (don't repeat)

- **Don't put segmented Picker in DocumentGroup's `.principal` toolbar slot.** DocumentGroup owns that slot for the document title — the picker was invisible or unresponsive. Either move out of DocumentGroup (done) or use a different placement.
- **Don't set WKWebView `baseURL` to the source document's parent directory.** Vendored scripts (marked.js, mermaid.js, highlight.js) load relative to baseURL — passing the document's dir makes them 404. Always use the bundle preview dir (or prefer `loadFileURL(_:allowingReadAccessTo:)`).
- **Don't use `.ignoresSafeArea(.keyboard, edges: .bottom)` on text editors.** That modifier lets the keyboard *cover* the text. The default (respecting the keyboard) is what you want.
- **Don't use DocumentGroup for a reader-first app.** Its "Create" primary CTA, its save-on-every-edit behavior, and its insistence on principal toolbar ownership all fight a reader's UX.
- **Don't rely on AppleScript taps for iOS Simulator UI automation.** Causes rotation issues and unreliable coordinates. For verification, screenshot the launch screen and trust the code for inner views.
- **Don't put `.regularMaterial` buttons over animated content.** Material blur re-samples the background every frame — if there's an animation running behind it, you're paying a full offscreen-render per tick. Either solid fills or a static background. (2026-04-18 — animated orbs behind two material buttons made the home screen felt unresponsive.)
- **Don't eagerly load all rendering dependencies upfront.** Mermaid.js at 3 MB was loading on every preview whether it was needed or not; WebContent process stayed unresponsive until parsing finished. Lazy-load heavy libraries on first use of their feature.
- **Don't compute `ShareLink(item: ...)` via a function with side effects.** `ShareLink(item: exportedFileURL())` where `exportedFileURL()` writes a temp file = one disk write per SwiftUI body render = one disk write per keystroke in Edit. Use `Transferable` (`FileRepresentation`) so the file is written only when the share is actually invoked.
- **Don't use `UIScreen.main.bounds` for view sizing in iOS 26.** Deprecated. For `inputAccessoryView`, UIKit auto-sizes to the keyboard width anyway — just set height in `intrinsicContentSize`.
- **Don't call `picker.dismiss(animated:)` inside a `PHPickerViewControllerDelegate` method when the picker is presented from a SwiftUI `.sheet` inside a `.fullScreenCover`.** The dismiss cascades through the presentation hierarchy and dismisses the parent fullScreenCover, killing the open document. Let SwiftUI dismiss via the binding (`showImagePicker = false`) instead.
- **Don't double-quote interpolated strings from `jsonString(...)` in JavaScript templates.** Helper returns `"hello"` already wrapped in quotes — `"window.x = \"\(escaped)\";"` produces `window.x = ""hello"";` which is invalid JS. Use `"window.x = \(escaped);"`. This silently broke image preview AND font CSS until found.
- **Don't use `UIFont.systemFont(ofSize:).fontDescriptor.withDesign(.rounded)` for SF Pro Rounded substitution.** That descriptor sometimes doesn't carry the attributes needed for `.rounded` to apply. Use `UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.rounded)` instead — reliably yields SF Pro Rounded.
- **Don't apply `.tint()` only at NavigationStack outer in a Settings Form.** Live theme changes won't propagate to pushed Picker sub-lists' selection checkmarks. Apply `.tint(themeColor)` directly on the Form too.
- **Don't use `.safeAreaInset(edge: .bottom)` for floating chrome that should overlay content.** That modifier reserves vertical space and pushes content up. Use `.overlay(alignment: .bottom)` so the content extends to the screen edge and the chrome floats over it.
- **Don't try to give WKWebView access to multiple root paths via `loadFileURL(allowingReadAccessTo:)`.** It only takes one. If you need WebKit to load resources from two locations, mirror everything into one parent dir (we picked Documents/) and load from there.
