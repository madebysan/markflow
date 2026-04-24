# Changelog

All notable shipped features and changes, organized by date.
Updated every session via `/save-session`.

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
