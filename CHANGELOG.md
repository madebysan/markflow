# Changelog

All notable shipped features and changes, organized by date.
Updated every session via `/save-session`.

---

## 2026-05-10 (session 5) — v0.2.0

User feedback round driven by a fan letter listing 4 issues + 2 feature requests; expanded into a broader UX pass while we were in the codebase. `MARKETING_VERSION` 0.1.0 → 0.2.0, `CURRENT_PROJECT_VERSION` 2 → 5.

### New features

- **Theme system** — 5 curated themes (Indigo, Forest, Sunset, Ocean, Graphite), each with separate light + dark hex values. `AppThemeCatalog` in `AccentColor.swift`, `accentColor` resolves per `userInterfaceStyle` via `UIColor` `dynamicProvider`. Replaces the free-form `ColorPicker` from an earlier draft.
- **Appearance preference** — System / Light / Dark switcher in Settings. `AppearancePreference` enum, applied via `.preferredColorScheme()` at WindowGroup root + on the SettingsView root (sheets cache env, so live switching needs the preference applied locally too).
- **Document font picker (6 options)** — System (SF Pro), Rounded (SF Pro Rounded, rebuilt with `preferredFontDescriptor.withDesign(.rounded)` so substitution actually takes), Charter (bundled iOS reading serif), Monospace (SF Mono), iA Writer (iA Writer Quattro S, open source SIL OFL, ~240 KB), JetBrains (JetBrains Mono, open source OFL, ~544 KB). Custom NavigationLink picker so each row renders in its own font (default `Picker` discards per-row `.font()`). Applies to both editor (`UIFont`) and preview (CSS via `setFontPreferences` JS).
- **Font size sliders** — Editor (12–24pt, syncs with pinch-to-zoom) + Preview (12–24pt, separate). CSS `--body-font-size` injected via JS.
- **Recents on Home** — Last 4 opened files via `RecentsStore.shared`, security-scoped bookmark `Data` persisted in UserDefaults, stale entries pruned on resolve failure. Welcome to Markflow button auto-hides when recents exist. Clear-recents button in Settings (with confirmation).
- **Image picker** — `PHPickerSheet` (no photo-library permission needed). Saves to `Documents/images/UUID-name.{jpg,png}`. PNG when image has alpha, JPEG q=0.9 otherwise. Inserts `![alt](images/UUID-name.ext)`. On Save / Save As, sibling images are copied to `<.md location>/images/` so other markdown apps resolve the relative paths.
- **Filename in nav bar + Options menu** — Centered title (editable via Rename). Top-trailing `Menu`: Rename → file system move, Save to Files → existing fileExporter, Share → existing ShareLink, Export as PDF → off-screen WKWebView + `createPDF`, Settings → opens SettingsView sheet from within doc.
- **Export as PDF** — `PDFExporter.swift`. Off-screen WKWebView (US Letter 612×792pt), reuses preview pipeline with selected font + size, renders via existing `render()` JS, posts a `renderDone` `WKScriptMessage` when complete (Promise chained), then `createPDF` writes to temp + presents share sheet via `IdentifiableURL` + `ShareSheet` `UIActivityViewController` wrapper.
- **Floating glass nav at bottom** — Single-icon toggle: pencil in Preview (tap to edit), eye in Edit (tap to preview). 48pt circle with `.ultraThinMaterial`, iOS 17+ `.symbolEffect(.replace)` swap animation. Used `.overlay(alignment: .bottom)` instead of `.safeAreaInset` so it doesn't reserve vertical space.
- **Floating Liquid Glass editor toolbar** — `inputAccessoryView` capsule with system blur, larger touch targets (40pt), padded from screen edges, capsule corner radius. Replaces the old edge-to-edge bar.
- **Interactive swipe-back gesture** — DragGesture (.simultaneousGesture, `.global` coordinate space) that requires origin x < 24pt. Document follows finger via `.offset(x:)`, snaps back if translation < 90pt, calls `attemptClose()` past threshold.
- **New file mode preference** — Edit / Preview default for newly-created docs. Existing files always open in Preview.

### Fixes

- **2.1 image-picker dismiss bug** — `PHPickerViewControllerDelegate` was calling `picker.dismiss(animated:)`, which under SwiftUI's `.sheet`-inside-`.fullScreenCover` cascades and dismisses the parent document. Removed; SwiftUI now dismisses via the `showImagePicker` binding.
- **2.2 preview JS string escaping** — `imageBasePath` and `setFontPreferences` were double-quoted (`jsonString` already wraps in `"..."`, the template added another `\"...\"`). Resulted in invalid JS, silently failed. Both image rendering and font CSS were broken until this fix.
- **2.3 hide-keyboard button no-op** — `inputAccessoryView`'s `self.window` is the keyboard's `UIInputWindow`, so `.endEditing(true)` did nothing. Switched to `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...)` walking the responder chain.
- **2.4 theme tint not propagating to inner pickers** — `.tint()` only on NavigationStack didn't reach pushed Picker sub-lists. Added `.tint(themeColor)` directly on the Form too. Browse button + brand glow on Home now read from `AppThemeCatalog.theme(for: themeID)` instead of hardcoded purple gradient.

### Infrastructure

- **PreviewAssets relocation** — `Documents/preview/` now mirrors all preview assets (preview.html, preview.js, marked, highlight, mermaid, CSS) on launch when bundle build version changes. Required because WKWebView's `loadFileURL(allowingReadAccessTo:)` only accepts one root, and we need read scope to cover both preview HTML and user-saved images under Documents.
- **Bundled fonts** — `Markflow/Resources/fonts/` ships iA Writer Quattro S (Regular + Bold) and JetBrains Mono (Regular + Bold), all SIL OFL. Registered in `Info.plist` `UIAppFonts`. Also mirrored to `Documents/preview/` with `@font-face` declarations in `preview.html` for WebKit consumption.
- **Build infrastructure** — `CURRENT_PROJECT_VERSION` 2 → 5 over the session (3, 4, 5 to force PreviewAssets re-mirror after preview.html / fonts changes).

### App Store hardening (added in companion session)

- **`PrivacyInfo.xcprivacy`** — required by Apple since May 2024. Declares `NSPrivacyTracking = false`, empty `NSPrivacyCollectedDataTypes`, and required-reason API usage for UserDefaults (`CA92.1` — App functionality). Wired into the bundle via `project.yml`'s `resources:` array.
- **Markdown sanitizer** — `preview.js` `sanitizeRenderedMarkdown(root)` strips `<script>`, `<iframe>`, `<form>`, etc.; removes inline event handlers + `srcdoc`; nukes `javascript:` / `vbscript:` URLs from `href` / `src`; adds `rel="noreferrer noopener"` to all links.
- **Mermaid security level → strict** — `securityLevel: 'loose'` → `'strict'`, `htmlLabels: false`. Closes the "raw HTML in mermaid labels" attack vector.
- **CSP `img-src` adds `file:`** — required since Markflow loads images via file:// URLs.
- **External-link navigation delegate** — `PreviewView.WKNavigationDelegate.decidePolicyFor` opens user-tapped non-file URLs externally via `UIApplication.shared.open()`. Without this, tapping a link in preview would replace the rendered HTML with the destination page.
- **`AppLinks.swift`** — centralizes website / support / privacy URL strings with safe `URL(string:)` construction. HomeView credit + SettingsView About section render only when URL construction succeeds.

### Reverted

- Initial attempt to set image base path to source's parent directory (so external sibling images would render in preview) — incomplete because WKWebView's `loadFileURL(allowingReadAccessTo:)` is scoped to Documents/, so file:// loads outside that scope are silently blocked. Reverted to always-Documents/ base path. Proper fix requires `WKURLSchemeHandler` (deferred to v0.3.0).

### Code organization

- New files: `AccentColor.swift` (theme/font/appearance/file-mode enums + HexColor helper), `RecentsStore.swift` (`@Observable` singleton + bookmark mgmt), `ImageStore.swift` (PNG/JPEG save with UUID prefix), `PreviewAssets.swift` (asset mirror), `PDFExporter.swift` (off-screen WKWebView + WKScriptMessageHandler), `AppLinks.swift` (centralized URLs), `PrivacyInfo.xcprivacy` (App Store privacy manifest), `Views/SettingsView.swift`, `Views/ImagePickerSheet.swift`, `Views/ShareSheet.swift` (UIActivityViewController wrapper + `IdentifiableURL`).

---

## 2026-04-24 (session 4)

### App Store resubmission

- **0.1.0 (2) uploaded and submitted for review** after Apple rejected 0.1.0 (1) on three guidelines. Build accepted into ASC; status: Waiting for Review.

### Fixes (rejection response)

- **5.2.5 trademark** — Subtitle `Markdown reader for iOS` → `Open .md files anywhere`. Home-screen tagline `"The iOS reader markdown was missing."` → `"The markdown reader you've been missing."`. Description cleaned of three other "iOS" marketing references (opener, "native iOS preview" bullet, "iOS 26 Liquid Glass nav bar" line).
- **2.1 blank-page bug** — `HomeView.swift`: Create button now calls `Self.newDocumentTemplate()` instead of passing `""`. Starter content (`# Untitled\n\nStart writing your markdown here.\n`) makes Preview mode render visible content on first appear, fixing the iPad Air 11" blank-canvas rejection. Verified on device by san.
- **1.5 Support URL** — Created `docs/support.md` with FAQ + `hi@santiagoalonso.com` contact. Swapped ASC Support URL from the GitHub issues tracker to `https://github.com/madebysan/markflow/blob/main/docs/support.md`.

### Metadata

- **ASC metadata updated live** — subtitle, description, Support URL, and App Review Notes all rewritten in App Store Connect. Reviewer Notes now lead with a `RESUBMISSION: 0.1.0 (2)` block calling out each fix so the reviewer can verify without re-reading the whole note.
- **`docs/app-store/metadata.md` synced** — spaced em-dashes removed from the description to match what was actually pasted into ASC. File now reflects live listing state for any future rebuild.
- **README tagline + Support section updated** — tagline matches the in-app tagline, Support section points at `docs/support.md` (GitHub issues kept as secondary path for public bug reports).

### Build infrastructure

- **Build number bumped** — `CURRENT_PROJECT_VERSION` 1 → 2 in `project.yml`, regenerated via xcodegen. Marketing version stays at `0.1.0`.
- **Release IPA** — fresh archive + export at `build/export/Markflow.ipa` (2.9 MB, Apple Distribution cert under team `QAMM2A6WRQ`, entitlement `application-identifier = QAMM2A6WRQ.com.san.markflow`).

### Status: resubmitted to App Store, awaiting review

Auto-release on approval. Two commits (`032defb`, `17585d5`) pushed to `main`.

---

## 2026-04-23 (session 3)

### App Store submission

- **Markflow v0.1.0 submitted to the App Store** — listed as `Markflow — Markdown Reader` (the shorter `Markflow` was taken). Awaiting Apple review.
- **App Store Connect listing complete** — paste-ready metadata at `docs/app-store/metadata.md`: subtitle "Markdown reader for iOS", Productivity primary / Utilities secondary category, age rating 4+, privacy declaration "Data Not Collected", auto-release on approval.
- **Screenshots captured** — 5 iPhone 17 Pro Max shots (1320×2868, `docs/app-store/screenshots/6.9-inch/`) and 5 iPad Pro 13" shots (2064×2752, `docs/app-store/screenshots/13-inch-ipad/`).
- **Privacy policy** — `docs/privacy-policy.md` published; URL points at the file in the public GitHub repo.

### Build infrastructure

- **Team ID corrected** — `project.yml` `DEVELOPMENT_TEAM` switched from `3KBA253B3F` (free personal team) to `QAMM2A6WRQ` (paid Apple Developer Program team that owns the Apple Distribution cert). Apple Distribution signing only works under the paid team.
- **Export compliance** — `ITSAppUsesNonExemptEncryption: false` added to `Info.plist`. Skips the encryption form on every future submission.
- **App icon flattened** — `icon-1024.png` had an alpha channel that Apple rejects. ImageMagick composited onto a flat blue→purple gradient (`#83ABF7 → #7869E4`) and stripped alpha.
- **Release archive shipped** — `xcodebuild archive -allowProvisioningUpdates` + `xcodebuild -exportArchive`, IPA delivered via Transporter (entitlement `application-identifier = QAMM2A6WRQ.com.san.markflow`).

### Status: submitted to App Store, awaiting review

Auto-release on approval. No further action required from us until Apple emails back.

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
