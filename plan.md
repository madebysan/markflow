# Markflow — Plan

## Done this session (2026-04-17)

- **Scaffold**: xcodegen project, SwiftUI + iOS 26, iPhone-only, initial build passing
- **Core document flow**: `MarkdownDocument` (FileDocument), WKWebView-based preview, TextEditor edit, segmented picker toggle
- **Preview rendering**: vendored `marked.js` + `highlight.js` + `mermaid.js`, GitHub-style light/dark CSS themes, task list checkboxes
- **Document-type registration**: hand-authored Info.plist with `CFBundleDocumentTypes` + `UTImportedTypeDeclarations` for `.md`/`.markdown`/`.mdown` — app now appears in iOS share sheet
- **Pinch zoom**: WKWebView native zoom in Preview, `MagnifyGesture` font scaling in Edit (`@AppStorage` persistence)
- **Read-only semantics**: switched from `DocumentGroup(newDocument:)` to `DocumentGroup(viewing:)`, then to `WindowGroup` + custom home. Original files are never modified.
- **Explicit export**: ShareLink in nav bar exports edits as `<name>-edited.md` to a temp file
- **Rebrand**: MDReader → Markflow, bundle ID `com.san.markflow`, icon installed in asset catalog (upscaled 824→1024)
- **Custom home page**: drop DocumentGroup's launch browser, add gradient HomeView with app icon, Markflow title, tagline, Browse (primary) + Create (secondary) CTAs, santiagoalonso.com credit link
- **Dark mode**: home page gradient and shadows swap via `@Environment(\.colorScheme)`; preview CSS already auto-switches
- **Nav redesign**: Preview/Edit picker moved to `ToolbarItem(.principal)`, Share to `.topBarTrailing`, close chevron to `.topBarLeading` — iOS 26 Liquid Glass pills
- **Preview bug fix**: WKWebView `baseURL` always points to bundle preview dir so vendored scripts load (was passing document parent URL, breaking marked.js loading)
- **Dead code removal**: deleted `MarkdownDocument.swift` (orphaned when we dropped DocumentGroup)

## Current state

- **Build status**: passing (`xcodebuild` + simulator iPhone 16e)
- **Physical device signing**: team `3KBA253B3F` configured. Needs one-time Xcode GUI provisioning on first device build (Signing & Capabilities → pick team).
- **Simulator**: iPhone 16 not available on this Mac, using iPhone 16e
- **Tagline**: "The iOS reader markdown was missing."

## Next steps

- [ ] First successful device build (needs Xcode GUI provisioning for `com.san.markflow` profile)
- [ ] Re-export app icon at native 1024×1024 (currently upscaled from 824)
- [ ] Decide on "Recents" list — dropped when we moved off DocumentGroup. Options: `@AppStorage` keyed by URL bookmarks, or list files in app's Documents folder.
- [ ] Persist in-memory edits as drafts (lost on close today). Options: `UserDefaults` keyed by source URL, or write to temp on change.
- [ ] Add press-state scale animation to home buttons (not-boring signature move)
- [ ] Decide on relative image path support — requires continuous security-scoped access to source directory

## Decisions & context

- **DocumentGroup dropped in favor of custom root.** Rationale: Markflow is a reader-first app — DocumentGroup's "Create" as primary CTA was wrong. Custom `WindowGroup + HomeView + .fileImporter + .onOpenURL` gives full UI control; share-sheet integration (Open in Markflow) still works via `CFBundleDocumentTypes` + `UTImportedTypeDeclarations`.
- **Mermaid vendored despite 3 MB cost.** User's example document (A24 presentation) leaned heavily on flowcharts. Rendering them as raw code blocks would have lost the visual flow. App binary grew ~1 MB → ~4.5 MB.
- **Preview rendering = WKWebView + marked.js** (not native `AttributedString(markdown:)`). Only way to render inline images, tables, and mermaid diagrams. Native APIs don't support any of them.
- **baseURL always bundle, never source URL parent.** Passing the source dir breaks relative script loading for marked.js/mermaid.js/highlight.js. Trade-off: relative image paths in user markdown don't resolve.
- **Edits live in memory only.** No auto-save, no draft persistence. User must explicitly export via Share to keep changes. Original file is never touched.

## Dependencies added

- **xcodegen** (`brew install xcodegen`, v2.44.1) — project generation from `project.yml`
- **Vendored JS libraries** (bundled, offline):
  - `marked.min.js` (~40 KB) — markdown → HTML
  - `highlight.min.js` (~125 KB) — syntax highlighting
  - `mermaid.min.js` (~3 MB) — flowchart rendering
  - `highlight-github.css` / `highlight-github-dark.css` — light + dark themes
- No Swift Package Manager dependencies

## v0-swift skill (parallel track)

This project was also the first real use of the custom `/v0-swift` skill. The skill itself lives at `~/.claude/skills/v0-swift/` and generated the initial scaffold + first three phases (scaffold, implement, launch) before the session shifted to interactive iteration. Known skill gaps surfaced:

- **Ralph-loop prompt-file workaround** — ralph-loop's CLI shell-parses its task argument, so multi-line markdown prompts fail. Workaround used: write the prompt to `.v0-swift/prompt.md` and pass a short "read and execute" pointer. Worth baking into the skill.
- **No reliable iOS Simulator CLI for taps** — AppleScript taps got the rotation wrong and screenshotted sideways. Skill's Phase 4 (Visual QA) should document this and scope its expectations to launch-screen verification only.
- **Document type registration** — skill mentions the plist approach; the reliable path (hand-authored `Info.plist` + `GENERATE_INFOPLIST_FILE: NO`) should be the default in the skill's scaffold phase, not the fallback.
