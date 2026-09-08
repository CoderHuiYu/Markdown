---
name: MarkdownEditor
description: A continuous iOS note canvas where reading and editing share one visual language.
colors:
  paper: "#ffffff"
  ink: "#000000"
  secondary-ink: "rgba(60, 60, 67, 0.60)"
  selection-fill: "rgba(118, 118, 128, 0.12)"
  quote-rule: "rgba(115, 121, 140, 0.40)"
  ios-link: "#007aff"
  task-green: "#01bc4a"
  lavender-highlight: "rgba(118, 123, 255, 0.30)"
  indigo-highlight: "rgba(31, 56, 139, 0.15)"
  night-paper: "#000000"
  night-ink: "#ffffff"
  night-link: "#0a84ff"
  night-task-green: "#30d158"
typography:
  display:
    fontFamily: "PingFang SC, Hiragino Sans, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.18
  headline:
    fontFamily: "PingFang SC, Hiragino Sans, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "23px"
    fontWeight: 700
    lineHeight: 1.18
  title:
    fontFamily: "PingFang SC, Hiragino Sans, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "19px"
    fontWeight: 700
    lineHeight: 1.18
  body:
    fontFamily: "PingFang SC, Hiragino Sans, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.56
  control:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "17px"
    fontWeight: 600
  code:
    fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "13px"
    fontWeight: 400
rounded:
  highlight: "4px"
  task: "6px"
  control: "12px"
  table: "16px"
spacing:
  compact: "4px"
  inline: "8px"
  section: "14px"
  canvas: "20px"
  canvas-top: "24px"
  heading-break: "28px"
  touch-target: "44px"
  formatting-bar: "54px"
components:
  formatting-control:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    size: "{spacing.touch-target}"
  formatting-control-selected:
    backgroundColor: "{colors.selection-fill}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    size: "{spacing.touch-target}"
  task-checkbox:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.task}"
    size: "20px"
  task-checkbox-checked:
    backgroundColor: "{colors.task-green}"
    textColor: "{colors.paper}"
    rounded: "{rounded.task}"
    size: "20px"
  document-canvas:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    padding: "24px 20px 56px"
---

# Design System: MarkdownEditor

## Overview

**Creative North Star: "The Continuous Note Canvas"**

The document is the interface. Reading and editing occupy the same calm white canvas, with native controls appearing only when they are useful. Hierarchy comes from Chinese-first typography, compact vertical rhythm, and restrained semantic decoration rather than cards or extra chrome.

The visual identity is editorial but not ornamental: ink remains dominant, secondary metadata recedes, and the only persistent color moments are the heading wash, system link blue, and task-completion green. Native iOS materials belong to controls; the note body remains flat and direct.

**Key Characteristics:**

- One uninterrupted document surface for reading and editing.
- Strong heading scale with more space above than below.
- Sparse semantic color: lavender hierarchy, blue links, and green completion.
- Native, compact controls with 44-point interaction targets.
- Chinese typography, Dynamic Type, light/dark appearance, and reduced motion are first-class.

## Colors

The palette is paper-and-ink with small semantic accents; dark appearance reverses the neutral canvas and uses the platform's brighter link and completion colors.

### Primary

- **Task Green:** Reserved for checked task state and its confirmation motion.
- **iOS Link Blue:** Used only for interactive links and the editing caret.

### Secondary

- **Lavender Wash:** A translucent underline behind level-two headings.
- **Indigo Wash:** A quieter underline behind level-three headings.

### Neutral

- **Paper and Ink:** The document's dominant background and text pair.
- **Secondary Ink:** Metadata, quotations, placeholders, and completed-task copy.
- **Quote Rule:** The quiet structural line beside quoted context.
- **Selection Fill:** The sole fill used to mark the active formatting command.

### Named Rules

**The Sparse Accent Rule.** Color communicates hierarchy, action, or completion; it never becomes general decoration.

**The Full-Contrast Reading Rule.** Read-only content keeps the same foreground contrast as editable content.

## Typography

**Display Font:** PingFang SC with Hiragino Sans and iOS system fallbacks  
**Body Font:** PingFang SC with Hiragino Sans and iOS system fallbacks  
**Label/Mono Font:** iOS system for controls; SF Mono, Menlo, or a monospace fallback for code

**Character:** The type system is optimized for long Chinese notes: plain, high-contrast body copy with compact, decisive heading steps. Dynamic Type scales each role through its corresponding native text style.

### Hierarchy

- **Display:** Level-one document title and major note boundaries.
- **Headline:** Level-two section headings with the stronger lavender wash.
- **Title:** Level-three headings with a quieter indigo wash.
- **Body:** Paragraphs, nested lists, quotations, and task labels.
- **Control:** Native formatting actions and Done; concise labels, never prose.

### Named Rules

**The Content-First Type Rule.** Weight and size establish hierarchy before color or container treatment.

## Layout

The note is a single vertical flow capped at a 760-point readable measure and centered when additional width is available. Phone layouts use 20-point horizontal canvas padding and 24 points at the top. Paragraphs stay tight; headings gain progressively larger space above them so sections remain scannable without divider clutter.

Editing does not introduce a second layout. The native formatting bar anchors to the keyboard layout guide, spans the available width, scrolls horizontally if accessibility sizing demands it, and reserves its height inside the document so the final line remains reachable.

## Elevation & Depth

The document canvas is flat and shadow-free. Depth belongs only to host-provided iOS navigation and the system chrome material behind the formatting bar; semantic content never sits on floating cards.

### Named Rules

**The Flat Document Rule.** Notes use spacing and type for structure; custom shadows and stacked surfaces stay out of the reading flow.

## Shapes

Most content has no enclosing shape. Small continuous corners belong to heading washes and formatting selections, task boxes use a compact softened square, and wide data tables use the largest radius. Pills are not part of the document language.

## Components

### Document Canvas

- **Surface:** Paper/ink in light appearance and the reversed neutral pair in dark appearance.
- **Width:** Full phone width with a centered 760-point maximum on wider hosts.
- **Behavior:** The same Vditor WYSIWYG DOM is used for reading and editing.

### Formatting Bar

- **Shape:** A full-width native material strip above the keyboard.
- **Commands:** H1, H2, H3, H4, body, unordered list, task list, and Done.
- **State:** The current block command receives a quiet selection fill; foreground content remains ink-colored.
- **Interaction:** Every command has a 44-point target and an explicit accessibility label.

### Task Items

- **Open:** A 20-point white checkbox is centered in a 44-point hit target.
- **Complete:** The box turns task green with a white check; the label becomes secondary and struck through.
- **Motion:** Completion uses one short spring-like size pulse and respects Reduce Motion.

### Heading Marks

- **Level Two:** A nine-point translucent lavender wash sits behind the baseline.
- **Level Three:** A six-point indigo wash provides a quieter echo.
- **Behavior:** The mark follows only the heading's text width, not the full container.

### Quotes and Tables

- **Quotes:** Secondary text with a two-point neutral rule and no filled card.
- **Tables:** A single rounded outline, transparent cells, subtle separators, and horizontal scrolling when needed.

## Do's and Don'ts

### Do:

- **Do** keep reading and editing on the same rendered canvas.
- **Do** preserve more space above a heading than below it.
- **Do** reserve 44-point hit targets even when the visible glyph is smaller.
- **Do** keep task state in exported Markdown and use lowercase `[x]` for completed items.
- **Do** apply Dynamic Type, dark appearance, and Reduce Motion through native traits.

### Don't:

- **Don't** introduce a raw-source editor as a parallel visual mode.
- **Don't** dim the whole note to communicate read-only state.
- **Don't** add cards, decorative shadows, or extra toolbar commands to the core surface.
- **Don't** use accent color where weight, spacing, or hierarchy already communicates the distinction.
- **Don't** rely on CDN assets or browser-local storage for document state.
