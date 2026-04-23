# Changelog

All notable shipped features and changes, organized by date.
Updated every session via `/save-session`.

---

## 2026-04-18 (session 2)

### Security

- **Content-Security-Policy** added to `preview.html`. User markdown rendered by marked.js can no longer exfiltrate document content via injected `<script>` tags — `connect-src 'none'` blocks outbound fetch/XHR, `script-src 'self'` blocks inline and third-party scripts. Required extracting the init script to a separate `preview.js` file.
- **Offline-first integrity** — the welcome tour no longer fetches a remote Unsplash image; replaced with a code example showing the markdown image syntax. Markflow now makes no network requests of its own.

### Ship prep

- **New native-resolution app icon** — 1648×1648 master replacing the previous upscaled 824→1024 render. Downsampled cleanly to 1024 (AppIcon) and 512 (HomeIcon).
- **Vendored-library attribution** added to README (marked, highlight.js, Mermaid).
- **Feedback section** in README linking to GitHub issues.
- **`backlog.md` untracked** — keeps session planning local, CHANGELOG remains the public record of shipped work.

### Features

- **Markdown toolbar** — keyboard-accessory toolbar in Edit mode with headings (H1/H2), bold, italic, strikethrough, link, image, bullet/numbered/task lists, quote, inline code, code block, and horizontal rule. Wraps selection when present, inserts placeholder at cursor otherwise. Toggles line prefixes off on second tap.
- **Welcome template** — `welcome.md` bundled in Resources, loaded as initial text when Create is tapped. Showcases all markdown styles (headings, emphasis, lists, tables, code blocks, mermaid, image, rule) so new users get a live tutorial.
- **Home screen polish** — animated ambient orbs drifting behind the icon (14s breathing loop), fade-in + slide-up entrance animation on brand + actions, press-state scale on Browse/Create buttons, subtle inner rim highlight on the icon.
- **Save + Save-as on exit** — tapping the back chevron with unsaved changes now surfaces a confirmation dialog: Save (overwrites the source file), Save as New File… (iOS document picker via `.fileExporter`), Discard Changes (red), Cancel. Save is hidden for brand-new documents created via Create. Security-scoped access to the source URL is held for the entire session so Save can write back without re-requesting permission.

### Infrastructure

- **EditView** rewritten on top of `UITextView` + `UIViewRepresentable` so cursor/selection mutations drive the toolbar. Pinch-to-zoom font scaling preserved.
- **Repo prep for GitHub** — MIT `LICENSE` added, `docs/screenshots/home.png` hero, README updated with screenshot + toolbar feature note, `.gitignore` extended (session notes, stale `MDReader.xcodeproj`, `.v0-swift/`). `plan.md`, `BUILD_REPORT.md`, `checkpoint.json`, and `.v0-swift/*` untracked.

---

## 2026-04-17 (session 1)

### Features

- **Scaffold** — xcodegen + SwiftUI iOS app, iPhone 16e simulator verified
- **Document viewing** — opens `.md` files via Files app share sheet (Open in Markflow), `.fileImporter` Browse flow, or `.onOpenURL`
- **Preview rendering** — `marked.js` + `highlight.js` + `mermaid.js` vendored; GitHub-flavored markdown, task lists, tables, syntax-highlighted code, mermaid diagrams all render
- **Edit mode** — `TextEditor` with monospaced font, `MagnifyGesture` font scaling (10–36 pt) persisted via `@AppStorage`
- **Pinch-to-zoom** — WKWebView 1×–5× in Preview, font scaling in Edit
- **Export flow** — read-only semantics; `ShareLink` in nav bar exports edits as `<name>-edited.md` to temp file, original never modified
- **Home page** — custom gradient home with 128pt app icon, title, tagline, Browse (primary gradient button) + Create (secondary material button), santiagoalonso.com credit
- **Dark mode** — adaptive home gradients and shadows, preview CSS already uses `prefers-color-scheme`
- **Nav bar** — iOS 26 Liquid Glass: close chevron (leading), Preview/Edit segmented picker (principal), Share (trailing)

### Branding

- **Renamed** MDReader → Markflow
- **Bundle ID** com.san.markflow (team 3KBA253B3F)
- **Tagline** "The iOS reader markdown was missing."
- **App icon** installed (paper-stack on purple gradient), HomeIcon asset for in-app display

### Share sheet registration

- Registered as owner-rank handler for `net.daringfireball.markdown` + `public.plain-text` via `CFBundleDocumentTypes`
- `UTImportedTypeDeclarations` for `.md`, `.markdown`, `.mdown` extensions
- `LSSupportsOpeningDocumentsInPlace` + `UISupportsDocumentBrowser` enabled

### Fixes

- **Edit toggle bug** — moved Picker out of `.toolbar` (was being clobbered by DocumentGroup's principal slot), later moved back into nav bar when DocumentGroup was replaced
- **Preview blank bug** — WKWebView `baseURL` was pointing to source document's parent, breaking relative script loading for marked.js/mermaid.js. Now always uses bundle preview dir.
- **Contrast** — tagline and credit link tuned to hit WCAG AA on both backgrounds
- **Keyboard hiding text** — removed `.ignoresSafeArea(.keyboard)` from EditView (was inverted)

### Infrastructure

- xcodegen as the project generator (`brew install xcodegen`, v2.44.1)
- Hand-authored `Info.plist` replaces xcodegen's generated one (needed for `CFBundleDocumentTypes` array)
- App size: ~1 MB → ~4.5 MB (mermaid.js is the bulk)

### Status: committed, not deployed

Signing configured for team `3KBA253B3F`; physical device build needs one-time Xcode GUI provisioning for `com.san.markflow` profile.
