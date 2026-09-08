# MarkdownEditor

`MarkdownEditor` is an iOS 15+ UIKit component that keeps Markdown reading and editing on the same visual surface. Its public API is native Swift; the editing engine is a locally bundled, trimmed Vditor 4.0.0 runtime hosted by `WKWebView`.

The built-in formatting bar intentionally supports only:

- H1, H2, H3, and H4
- Paragraph text
- Unordered lists
- GFM task lists (`- [ ]` and `- [x]`)
- Done

## Installation

During development, add this repository in Xcode and select the `Vditor` branch:

```swift
dependencies: [
    .package(
        url: "https://github.com/CoderHuiYu/Markdown.git",
        branch: "Vditor"
    )
]
```

Then add the `MarkdownEditor` product to the Earbuds target.

## UIKit

```swift
import MarkdownEditor

var configuration = MarkdownEditorConfiguration()
configuration.isEditable = false
configuration.allowsTaskInteractionInReadMode = true

let editorView = MarkdownEditorView(configuration: configuration)
editorView.setMarkdown(markdown)

// Reading and editing use the same view and theme.
editorView.isEditable = true
editorView.focus()

editorView.onMarkdownChange = { markdown in
    // Update the note draft.
}

editorView.onDone = { markdown in
    // Persist the note and leave editing mode.
}
```

When the editor is part of an existing scrolling note page, let the host own
vertical scrolling and move the formatting bar to the screen-level keyboard
guide:

```swift
var configuration = MarkdownEditorConfiguration()
configuration.backgroundColor = notesBackgroundColor
configuration.contentInsets = .init(top: 0, leading: 26, bottom: 0, trailing: 26)

let editorView = MarkdownEditorView(configuration: configuration)
editorView.isScrollEnabled = false
editorView.onContentHeightChange = { height in
    editorHeightConstraint.constant = height
}
editorView.onRequestEditing = {
    beginEditingNote()
}
editorView.attachFormattingBar(to: view)
```

Programmatic formatting is also available:

```swift
editorView.apply(.heading2)
editorView.apply(.paragraph)
editorView.apply(.unorderedList)
editorView.apply(.taskList)
```

Use `MarkdownEditorViewDelegate` when delegate-based integration fits the host controller better than closures.

## Behavior

- Vditor JavaScript, CSS, Lute, icons, and Chinese localization are bundled in the Swift package. The editor does not require a CDN.
- Vditor cache is disabled and the `WKWebView` uses a non-persistent data store.
- Task completion state is exported in Markdown rather than stored separately in browser local storage.
- Existing Markdown constructs are kept by Vditor even though the native formatting bar exposes only the compact command set above.
- Nested unordered lists are preserved and rendered with distinct first- and second-level markers.
- Dynamic Type, light/dark appearance, reduced motion, keyboard dismissal, and 44-point toolbar targets are supported.

## Demo

Open `Markdown/Markdown.xcodeproj`. The Demo consumes the root package through a local Swift Package reference and demonstrates reading, editing, task toggling, Markdown callbacks, and external-link handling.

## Vendored dependency

The package contains a trimmed Vditor 4.0.0 distribution under `Sources/MarkdownEditor/Resources/Vditor`. See `THIRD_PARTY_NOTICES.md` and the bundled Vditor license.
