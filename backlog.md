# Backlog

## Added 2026-04-17

- [ ] Recents list on home screen — track opened file URLs via `@AppStorage` and security-scoped bookmarks, display as a list below Browse/Create
- [ ] Draft persistence for in-memory edits — currently edits are lost if the document is closed without exporting; consider `UserDefaults` keyed by source URL or periodic temp writes
- [ ] Relative image path support — requires maintaining security-scoped access to source directory for the lifetime of the document view, or copying co-located images to temp on open
- [ ] Re-export app icon at native 1024×1024 — current master is upscaled from 824px source
- [ ] Live preview mode — rendered preview that updates as you type in Edit (currently requires tab switch)
- [ ] Syntax highlighting in Edit view — currently only applies in Preview; user would see highlighted source as they type
- [ ] Search within document — find-in-doc for both Preview and Edit modes
- [ ] Large file handling — marked.js is synchronous, files >1 MB may stutter the preview; consider streaming or worker-based parsing
- [ ] First-run onboarding — explain share-sheet integration ("Open any .md in Files → Share → Markflow")
