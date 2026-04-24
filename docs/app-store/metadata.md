# Markflow — App Store Metadata

Paste-ready copy for App Store Connect submission. Character limits noted.

---

## App name (30 char max)

```
Markflow — Markdown Reader
```
26 / 30

(Registered. The shorter `Markflow` was already taken on the App Store.)

## Subtitle (30 char max)

```
Open .md files anywhere
```
23 / 30 ← submitted 0.1.0 (2)

**Rejected subtitle from 0.1.0 (1):** `Markdown reader for iOS` — Apple 5.2.5 rejection (trademark). Do not use "iOS", "iPhone", "iPad", or "Mac" in subtitles.

**Alternates (also safe):**
- `Read and edit markdown` — 22 / 30

## Promotional text (170 char max, editable without new build)

```
A native reader and editor for .md files. Open from anywhere, render with code blocks, mermaid diagrams, and tables. No login. No tracking. No network.
```
148 / 170

## Description (4000 char max)

```
The markdown reader you've been missing.

Markflow opens .md files from Files, Mail, Safari downloads, or the share sheet and renders them properly. GitHub-flavored markdown, syntax-highlighted code, mermaid diagrams, tables, task lists, and more.

Originals are never touched. Edits live in memory until you explicitly Save, Save as New File, or Share a copy.


WHAT YOU CAN DO

• Open any .md, .markdown, or .mdown file from any app
• Read with a clean, native preview
• Edit with a markdown toolbar above the keyboard. Bold, italic, headings, lists, links, images, code, quotes, all one tap away.
• Pinch to zoom in both Preview and Edit
• Export an edited copy via the system share sheet
• Tap Create to start a new blank file, or "Welcome to Markflow" for a full feature tour


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

Built native with SwiftUI and the Liquid Glass nav bar. Light and dark mode. Adaptive home screen. Stock Apple Human Interface Guidelines throughout.


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

- **Support URL:** `https://github.com/madebysan/markflow/blob/main/docs/support.md`
- **Marketing URL:** `https://santiagoalonso.com`
- **Privacy Policy URL:** `https://github.com/madebysan/markflow/blob/main/docs/privacy-policy.md`

**Rejected Support URL from 0.1.0 (1):** `https://github.com/madebysan/markflow/issues` — Apple 1.5 rejection (dev issue tracker, not user-facing support).

## App Privacy (nutrition label)

Select: **Data Not Collected** ✅

No further checkboxes required. Skip the entire data-collection grid.

## App Review Information

- **Sign-in required:** No
- **Demo account:** N/A
- **Contact info:** san's email + phone
- **Notes to reviewer:**

```
RESUBMISSION: 0.1.0 (2)

This build addresses all three issues from the 4/24/2026 rejection of 0.1.0 (1):

1. 5.2.5 Trademark: Subtitle changed from "Markdown reader for iOS" to "Open .md files anywhere". Home-screen tagline and description also cleaned of "iOS" references.

2. 2.1 App Completeness (blank page on Create). Root cause: Create passed an empty string to the document view, which entered Edit mode with no content and no auto-shown keyboard, rendering as blank on iPad. Fix: Create now loads a visible starter template ("# Untitled" + short paragraph) so Preview mode shows rendered content on first appear.

3. 1.5 Support URL: Replaced GitHub issues tracker URL with a user-facing support page at github.com/madebysan/markflow/blob/main/docs/support.md (FAQ + contact email).

---

Markflow is a markdown reader and editor for .md files.

No login, no network, no permissions. The app reads files you open via Files, Mail, or the share sheet and renders them locally in a sandboxed WKWebView.

To test:
1. Tap "Welcome to Markflow" on the home screen. A full markdown tour loads (headings, code blocks, mermaid diagrams, tables). Use the Preview/Edit picker in the nav bar to switch modes.
2. Tap "Create" to start a new blank document with a starter heading. Opens in Preview mode; tap Edit to write.
3. Tap "Browse" to pick any .md file from the Files app.
4. The share button in the nav bar exports an edited copy.

The vendored mermaid.min.js (3 MB) renders diagrams locally. No remote code execution. CSP is locked to script-src 'self'.
```

## Version Release

- Automatic after approval

## Build

- 0.1.0 (build 2) — resubmission after 0.1.0 (1) rejection

## Changes in 0.1.0 (2) — resubmission notes

Addresses all three issues from Apple's 4/24/2026 review of 0.1.0 (1):

1. **5.2.5 Legal: Intellectual Property (trademark)** — Subtitle changed from `Markdown reader for iOS` to `Open .md files anywhere`. Home-screen tagline changed from "The iOS reader markdown was missing" to "The markdown reader you've been missing". All other "iOS" references removed from description.

2. **2.1 Performance: App Completeness (blank page bug)** — On iPad Air 11" M3, tapping Create showed a blank page. Root cause: Create passed an empty string to DocumentView which auto-switched to Edit mode; UITextView with no content and no auto-focused keyboard rendered as blank. Fix: Create now loads a minimal starter template (`# Untitled\n\nStart writing your markdown here.`) so Preview mode immediately shows visible rendered content.

3. **1.5 Safety: Developer Information (Support URL)** — Replaced `github.com/madebysan/markflow/issues` (dev-facing issue tracker) with a user-facing support page that has FAQ, how-to-get-help, and a contact email.
