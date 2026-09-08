# Product

<!-- impeccable:product-schema 1 -->

## Platform

iOS 15 and later, using UIKit.

## Stack

- Swift Package Manager library consumed by Earbuds.
- UIKit public API.
- A locally bundled Vditor runtime hosted in `WKWebView`; production use must not depend on a CDN.
- A runnable iOS Demo app remains in this repository.

## Users

Earbuds users reading and editing notes on iPhone. Editing should feel like editing the rendered document rather than switching to a visually unrelated Markdown source field.

## Product Purpose

Provide a reusable Markdown component whose reading and editing surfaces share the same layout and visual treatment. The component must round-trip Markdown without losing supported structure or task completion state.

## Operating Context

- A note opens in reading mode and can switch into editing mode.
- The editing accessory exposes only H1, H2, H3, H4, body text, unordered list, task list, and Done.
- Earbuds owns note persistence; the package reports Markdown changes and exports the current Markdown value.

## Capabilities and Constraints

- Minimum deployment target: iOS 15.
- Public integration must remain native Swift/UIKit even though the editing engine is web-based.
- Supported authoring commands: H1-H4, paragraph, unordered list, and GFM task list.
- Task items serialize as `- [ ]` and `- [x]`; checked state must live in Markdown rather than browser-local storage.
- Reading and editing must use the same rendering engine and theme to avoid style drift.
- Existing reader typography, spacing, heading decoration, list treatment, task-list appearance, Dynamic Type behavior, light/dark appearance, and Chinese content support are visual constraints to preserve.
- Existing Markdown outside the limited authoring toolbar must not be silently discarded during load/edit/export round trips.

## Brand Commitments

Preserve the former reader's visual direction—its typography, spacing, heading highlights, list hierarchy, and green task completion state. This work changes the editor architecture, not the established note-reading identity.

## Evidence on Hand

- `Sources/MarkdownEditor/Resources/Vditor/dist/css/content-theme/earbuds.css`: migrated reader styling and task interaction treatment.
- `Sources/MarkdownEditor/MarkdownEditorTypes.swift`: Dynamic Type base sizes migrated from the former reader.
- Repository history before the `Vditor` branch: original reader CSS, sizing, and task-list implementation used as migration evidence.
- `Markdown/Markdown/7月29日 云同步功能逻辑与AI联动规则.md`: representative Chinese Markdown document.
- The user-provided editing accessory reference with H1-H4, body, unordered-list, task-list, and Done controls.
