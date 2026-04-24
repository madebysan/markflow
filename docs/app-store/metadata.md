# Markflow — App Store Metadata

Paste-ready copy for App Store Connect submission. Character limits noted.

---

## App name (30 char max)

```
Markflow
```
8 / 30

## Subtitle (30 char max)

**Pick one:**

- `Markdown reader for iOS` — 23 / 30 ← recommended
- `Open .md files anywhere` — 23 / 30
- `Read and edit markdown` — 22 / 30
- `Native markdown for iPhone` — 26 / 30

## Promotional text (170 char max, editable without new build)

```
A native reader and editor for .md files. Open from anywhere, render with code blocks, mermaid diagrams, and tables. No login. No tracking. No network.
```
148 / 170

## Description (4000 char max)

```
The iOS reader markdown was missing.

Markflow opens .md files from Files, Mail, Safari downloads, or the share sheet and renders them properly — GitHub-flavored markdown, syntax-highlighted code, mermaid diagrams, tables, task lists, and more.

Originals are never touched. Edits live in memory until you explicitly Save, Save as New File, or Share a copy.


WHAT YOU CAN DO

• Open any .md, .markdown, or .mdown file from any app
• Read with a clean, native iOS preview
• Edit with a markdown toolbar above the keyboard — bold, italic, headings, lists, links, images, code, quotes, all one tap away
• Pinch to zoom in both Preview and Edit
• Export an edited copy via the system share sheet
• Tap Create to start a new file with a full markdown tour template


WHAT IT RENDERS

• Headings, lists, blockquotes, links, images
• Syntax-highlighted code blocks
• Mermaid flowcharts and diagrams
• GitHub-flavored markdown tables
• Task lists with checkboxes
• Inline images (absolute URLs)


PRIVACY

Markflow makes zero network requests and collects zero data. No accounts. No login. No analytics. No tracking. No ads. The renderer is a sandboxed local file with a Content Security Policy that blocks all remote resources.

Your files stay on your device.


DESIGN

Built native for iOS with SwiftUI and the iOS 26 Liquid Glass nav bar. Light and dark mode. Adaptive home screen. Stock Apple Human Interface Guidelines throughout.


WHO IT'S FOR

• Writers who keep notes in markdown
• Developers reading READMEs and docs on the go
• Anyone who's been emailed a .md and had nowhere to open it
• People who want a markdown reader that does one thing well


Open source. MIT licensed. github.com/madebysan/markflow
```

~1,800 / 4,000

## Keywords (100 char max, comma-separated, no spaces)

```
markdown,md,reader,editor,notes,writing,readme,docs,text,mermaid
```
65 / 100

**Notes on keyword choices:**
- Dropped `github` — Apple sometimes flags brand names in keywords
- Dropped generic `text` first round, kept since file association is `text/markdown`
- Added `mermaid` — niche but distinguishing feature, likely zero competition
- `notes` and `writing` cast a wider productivity net

## Category

- **Primary:** Productivity
- **Secondary:** Utilities

## Age rating

```
4+
```

## Copyright

```
© 2026 Santiago Alonso
```

## URLs

- **Support URL:** `https://github.com/madebysan/markflow/issues`
- **Marketing URL:** `https://santiagoalonso.com`
- **Privacy Policy URL:** `https://github.com/madebysan/markflow/blob/main/docs/privacy-policy.md`

## App Privacy (nutrition label)

Select: **Data Not Collected** ✅

No further checkboxes required. Skip the entire data-collection grid.

## App Review Information

- **Sign-in required:** No
- **Demo account:** N/A
- **Contact info:** san's email + phone
- **Notes to reviewer:**

```
Markflow is a markdown reader and editor for .md files.

No login, no network, no permissions. The app reads files you open via Files / Mail / share sheet and renders them locally in a sandboxed WKWebView.

To test:
1. Tap "Create" on the home screen — a welcome.md template loads with the full markdown tour (headings, code blocks, mermaid diagrams, tables).
2. Or tap "Browse" and pick any .md file from the Files app.
3. Use the Preview/Edit segmented picker in the nav bar to switch modes.
4. The share button in the nav bar exports an edited copy.

The vendored mermaid.min.js (3 MB) renders diagrams locally — no remote code execution. CSP is locked to script-src 'self'.
```

## Version Release

- Automatic after approval

## Build

- 0.1.0 (build 1)

---

## Open decisions for san

1. **Subtitle pick** — recommend `Markdown reader for iOS`. It's the most search-friendly.
2. **Description length** — current ~1,800 char draft is tight and scannable. Could expand to 3,000+ if you want more hooks (e.g., "Why I built Markflow" paragraph).
3. **App preview video** — optional, not in scope for v0.1.0. Skip.
