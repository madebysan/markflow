# Autonomous Build Task: MDReader iOS v0

## First action
Read `/Users/san/Projects/md-reader/plan.md` and `~/.claude/skills/v0-swift/references/phase-definitions.md` before doing anything else.

## Completion signal
When all phases pass, emit on its own line:

```
<promise>V0_SWIFT_COMPLETE</promise>
```

Do not emit prematurely.

## Environment
- Working directory: `/Users/san/Projects/md-reader`
- iOS target: 26.0
- Simulator device: iPhone 16e
- Project name (xcodegen): `MDReader`
- Folder name: `md-reader`
- Bundle ID: `com.san.mdreader`
- xcodegen at `/opt/homebrew/bin/xcodegen`

## Phases (see phase-definitions.md for full detail)

1. **Scaffold** — write `project.yml`, minimal `MDReaderApp.swift` + `ContentView.swift`, `xcodegen generate`, first `xcodebuild build` → must exit 0
2. **Implement** — in this order: `MarkdownDocument.swift` → `Resources/preview.html` + vendored `marked.min.js` (curl from jsdelivr) → wire `DocumentGroup` in App → `Views/DocumentView.swift` (segmented Picker in ToolbarItem.principal) → `Views/EditView.swift` (TextEditor) → `Views/PreviewView.swift` (WKWebView via UIViewRepresentable)
3. **Build & launch** — `xcrun simctl boot`, install .app, launch, verify process running
4. **Visual QA** — screenshot via `xcrun simctl io booted screenshot`, analyze, fix P0+P1 issues. Max 2 passes.
5. **Polish** — stock HIG so minimal. Ensure empty-file state looks okay, keyboard doesn't cover text.
6. **Verify & report** — clean build, final screenshot, git commit, write `BUILD_REPORT.md` using `~/.claude/skills/v0-swift/references/report-template.md`

## Critical implementation notes

**Document type registration (trickiest part):**
- Option A: project.yml INFOPLIST_KEY approach (may not work for arrays)
- Option B (reliable fallback): write hand-authored `MDReader/Info.plist` with CFBundleDocumentTypes array, set `GENERATE_INFOPLIST_FILE: NO` and `INFOPLIST_FILE: MDReader/Info.plist` in project.yml
- Test Option A first, fall back to B if build fails with plist errors

**FileDocument UTIs:**
```swift
static var readableContentTypes: [UTType] {
    [.plainText, UTType("net.daringfireball.markdown") ?? .plainText]
}
```

**Vendor marked.js:**
```bash
curl -sL -o MDReader/Resources/marked.min.js https://cdn.jsdelivr.net/npm/marked/marked.min.js
```

**WKWebView wrapper pattern:**
- `makeUIView`: create WKWebView, load preview.html from `Bundle.main.url(forResource:"preview", withExtension:"html")` with `baseURL: document.fileURL?.deletingLastPathComponent()`
- `updateUIView`: when markdown changes, call `evaluateJavaScript("render(\(jsonEncodedMarkdown))")`
- JSON-encode the markdown string (use `JSONEncoder` on a single-element array, strip brackets) to safely escape quotes/newlines for JS

**Segmented picker placement:**
```swift
.toolbar {
    ToolbarItem(placement: .principal) {
        Picker("Mode", selection: $mode) {
            Text("Preview").tag(Mode.preview)
            Text("Edit").tag(Mode.edit)
        }
        .pickerStyle(.segmented)
    }
}
```

## Guardrails

1. Never `swift build` — use `xcodebuild` with iOS Simulator destination
2. Never commit broken builds
3. Never `--no-verify` on git
4. Never `rm -rf` the project dir to recover — use `git reset --hard`
5. Never skip Phase 3 (launch verification)
6. No third-party Swift packages; marked.js is a resource file
7. Consult `~/.claude/skills/swiftui-expert-skill/references/` for iOS 26 API correctness
8. Update `checkpoint.json` at every phase transition

## On stuck
- Two attempts with different approaches, still failing → add to `deferred_to_v1`, commit what works, move on
- If API is unfamiliar, read `~/.claude/skills/swiftui-expert-skill/references/latest-apis.md`
- If truly stuck, spawn `fullstack-developer` Task agent with the error

## Exit criteria for each phase

| Phase | Must succeed before next |
|-------|--------------------------|
| 1 | `xcodebuild build` returns 0 |
| 2 | `xcodebuild build` returns 0 after every feature |
| 3 | `xcrun simctl launch` succeeds, app process visible |
| 4 | All P0+P1 screenshot issues fixed OR 2 passes complete |
| 5 | Build still passes after polish commits |
| 6 | Clean build passes, screenshot saved to `.v0-swift/screenshots/final.png`, git commit exists, BUILD_REPORT.md written |

## Begin

Start with Phase 1 now. Do not ask any questions. All decisions pre-approved in plan.md's `complexity_overrides`.
