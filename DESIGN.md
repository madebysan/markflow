# Markflow — Design

Living design authority for Markflow. Describes visual identity, UI patterns, and decisions as they exist in code. Updated alongside the code, not as a locked spec.

## Atmosphere

Calm, writerly, brand-forward. Not a utility app — it's the *place* for markdown on iOS. Purple/indigo brand heritage from the icon carries into the home screen; document reading is stock Apple HIG so the content wins.

## Colors

### Brand

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| Brand primary (gradient start) | `#7580F2` | `#7580F2` | Browse button, icon accents |
| Brand primary (gradient end)   | `#8E6BF2` | `#8E6BF2` | Browse button, icon accents |
| Brand shadow                   | `#594DCC` @ 28% / 45% | `#594DCC` @ 55% / 65% | Icon halo, button depth |

### Home gradient

| State | Colors |
|-------|--------|
| Light | `#EDEFFF` → `#DED6FF` (lavender wash, top-leading → bottom-trailing) |
| Dark  | `#140F2E` → `#231742` (deep indigo, top-leading → bottom-trailing) |

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

- **Brand title** — 42pt bold, tracking -0.8, SF Pro
- **Tagline** — 17pt regular, line-height ~1.2, `.primary.opacity(0.72)` for contrast
- **Button label** — 18pt semibold
- **Credit** — 13pt medium, 55% / 80% primary opacity (split for "Made by" / link)
- **Preview body** — 17pt `-apple-system`, line-height 1.5
- **Preview headings** — 28/22/19pt bold (H1/H2/H3)
- **Preview code** — 14–15pt SF Mono / Menlo

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

### Primary CTA

Full-width gradient button, 56pt tall, 18pt corner radius, brand gradient fill, white text + icon (18pt semibold), tinted drop shadow matching brand gradient. Used for: Browse (main Markflow action). Signals: "do this — it's the point of the app."

### Secondary CTA

Full-width material button, 56pt tall, 18pt corner radius, `.regularMaterial` fill, 12% primary stroke, primary-color text + icon (same weight as primary). Used for: Create. Signals: "available but less frequent."

### Nav bar items (iOS 26)

Close / picker / share all sit in `ToolbarItem` placements. iOS 26's Liquid Glass renders them as glass pills automatically — no custom styling. Segmented Picker in `.principal`, Share in `.topBarTrailing`, Close chevron in `.topBarLeading`.

### Preview / Edit toggle

Segmented `Picker` in the nav bar's principal slot, 180pt fixed width, `.segmented` style. Binding drives a `switch` over the two content views. Preview state is not persisted between documents.

### Share / Export

`ShareLink` in `.topBarTrailing` with a temp-file URL built on-demand from the current working text. Export filename derived from source (`<base>-edited.md`). Disabled when `workingText` is empty (e.g., new blank document with nothing typed).

## Shared components

- `HomeView` — home screen (`Markflow/Views/HomeView.swift`)
- `DocumentContainer` — private wrapper inside HomeView.swift, provides NavigationStack + toolbar title
- `DocumentView` — document reader/editor root (`Markflow/Views/DocumentView.swift`)
- `PreviewView` — `UIViewRepresentable` wrapping WKWebView (`Markflow/Views/PreviewView.swift`)
- `EditView` — `TextEditor` with magnification gesture (`Markflow/Views/EditView.swift`)
- `OpenedDocument` — model struct: `id`, `text`, `sourceURL?` (defined in HomeView.swift)

## Decisions

- **Read-only by default, explicit export only.** (2026-04-17) Markdown files often belong to someone else — silently overwriting the source on edit is wrong. Edits live in memory, Share sheet exports a copy.
- **Custom home replaces DocumentGroup launch browser.** (2026-04-17) Markflow is a reader; Browse should be primary, not Create. DocumentGroup's default order is wrong for this app.
- **WKWebView + vendored JS for preview, not native AttributedString.** (2026-04-17) Only path to rendering inline images, tables, mermaid diagrams. Native markdown APIs don't support any of these.
- **Mermaid diagrams included despite 3 MB cost.** (2026-04-17) Real documents lean on flowcharts. Losing them would be worse than the binary size hit.
- **iOS 26 target (not 17 or 18).** (2026-04-17) New install, no legacy users, lets us use Liquid Glass toolbar styling for free.
- **iPhone only, no iPad.** (2026-04-17) Keeps layout simple for v0. Universal target can be a v1 move.
- **Close chevron, not "Done" text.** (2026-04-17) iOS 26 pattern; chevron reads as "back to home" better than modal-dismiss wording.

## Anti-patterns (don't repeat)

- **Don't put segmented Picker in DocumentGroup's `.principal` toolbar slot.** DocumentGroup owns that slot for the document title — the picker was invisible or unresponsive. Either move out of DocumentGroup (done) or use a different placement.
- **Don't set WKWebView `baseURL` to the source document's parent directory.** Vendored scripts (marked.js, mermaid.js, highlight.js) load relative to baseURL — passing the document's dir makes them 404. Always use the bundle preview dir.
- **Don't use `.ignoresSafeArea(.keyboard, edges: .bottom)` on text editors.** That modifier lets the keyboard *cover* the text. The default (respecting the keyboard) is what you want.
- **Don't use DocumentGroup for a reader-first app.** Its "Create" primary CTA, its save-on-every-edit behavior, and its insistence on principal toolbar ownership all fight a reader's UX.
- **Don't rely on AppleScript taps for iOS Simulator UI automation.** Causes rotation issues and unreliable coordinates. For verification, screenshot the launch screen and trust the code for inner views.
