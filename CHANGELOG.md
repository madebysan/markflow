# Changelog

## Unreleased

- Images next to a file opened from Files or another app now show in the preview. iOS only lets Markflow read the file itself, so the first time, a **Show images from this file's folder** button asks you to pick that folder; Markflow remembers it after that.
- Task list checkboxes (`- [x]`) show again in the preview. A safety filter added in May removed every form input, which turned them into plain bullets.

## 0.2.0 (2026-05-12)

- Five themes, each with light and dark accents, and a System / Light / Dark appearance setting.
- Six document fonts: System, Rounded, Charter, Monospace, iA Writer Quattro and JetBrains Mono.
- Separate font sizes for the editor and the preview.
- Recents on Home: the last four opened files, clearable in Settings.
- Insert images from your photo library without granting library access. Images are saved next to your file when you save.
- The file name appears as the title, with a menu for Rename, Save to Files, Share, Export as PDF and Settings.
- Export as PDF.
- A floating button switches between Preview and Edit, and the editor toolbar floats above the keyboard.
- Swipe from the left edge to close a document.
- Choose whether new files open in Edit or Preview.
- Fixes: inserting an image no longer closes the document; images and fonts render in Preview; the hide-keyboard button works; the theme color applies throughout Settings.
- Safer preview: a privacy manifest, sanitized Markdown, strict Mermaid rendering, and links that open in Safari instead of inside the preview.

## 0.1.0 (2026-04-26)

First App Store release.

- Open Markdown files from Files, Mail, Safari and the share sheet, or browse for them.
- Rendered preview with GitHub-flavored Markdown, syntax-highlighted code, Mermaid diagrams, tables and task lists.
- Edit mode with a Markdown toolbar for headings, emphasis, links, images, lists, quotes and code.
- Pinch to zoom in Preview and Edit.
- Files open read-only; on close you can Save, Save as New File or discard your edits.
- A welcome document that shows every supported style.
- Dark mode.
- The preview blocks scripts and outbound requests from document content.
