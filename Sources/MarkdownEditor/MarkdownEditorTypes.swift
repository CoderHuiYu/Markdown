import UIKit

/// Block styles exposed by the compact native formatting bar.
public enum MarkdownBlockStyle: String, CaseIterable, Sendable {
    case heading1 = "h1"
    case heading2 = "h2"
    case heading3 = "h3"
    case heading4 = "h4"
    case paragraph
    case unorderedList
    case taskList
}

/// Runtime options for ``MarkdownEditorView``.
public struct MarkdownEditorConfiguration {
    /// Text shown when the document is empty.
    public var placeholder: String

    /// Whether text is editable when the view first loads.
    public var isEditable: Bool

    /// Shows the native H1-H4/body/list/task-list bar while the editor has focus.
    public var showsFormattingBar: Bool

    /// Allows task checkboxes to be toggled while text editing is disabled.
    public var allowsTaskInteractionInReadMode: Bool

    /// Base typography values. Dynamic Type scaling is applied by the view.
    public var theme: MarkdownEditorTheme

    /// Surface color shared by the native container and the web document.
    public var backgroundColor: UIColor

    /// Padding around the rendered document. The formatting bar inset is added
    /// to the bottom value only while the editor has focus.
    public var contentInsets: NSDirectionalEdgeInsets

    public init(
        placeholder: String = "开始记录…",
        isEditable: Bool = false,
        showsFormattingBar: Bool = true,
        allowsTaskInteractionInReadMode: Bool = true,
        theme: MarkdownEditorTheme = .earbuds,
        backgroundColor: UIColor = .systemBackground,
        contentInsets: NSDirectionalEdgeInsets = .init(
            top: 24,
            leading: 20,
            bottom: 56,
            trailing: 20
        )
    ) {
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.showsFormattingBar = showsFormattingBar
        self.allowsTaskInteractionInReadMode = allowsTaskInteractionInReadMode
        self.theme = theme
        self.backgroundColor = backgroundColor
        self.contentInsets = contentInsets
    }
}

/// Base point sizes used to build the CSS theme. Values are scaled with
/// `UIFontMetrics` whenever the content-size category changes.
public struct MarkdownEditorTheme {
    public var bodyPointSize: CGFloat
    public var listPointSize: CGFloat
    public var heading1PointSize: CGFloat
    public var heading2PointSize: CGFloat
    public var heading3PointSize: CGFloat
    public var heading4PointSize: CGFloat
    public var codePointSize: CGFloat
    public var lineHeightMultiplier: CGFloat

    public init(
        bodyPointSize: CGFloat,
        listPointSize: CGFloat,
        heading1PointSize: CGFloat,
        heading2PointSize: CGFloat,
        heading3PointSize: CGFloat,
        heading4PointSize: CGFloat,
        codePointSize: CGFloat,
        lineHeightMultiplier: CGFloat
    ) {
        self.bodyPointSize = bodyPointSize
        self.listPointSize = listPointSize
        self.heading1PointSize = heading1PointSize
        self.heading2PointSize = heading2PointSize
        self.heading3PointSize = heading3PointSize
        self.heading4PointSize = heading4PointSize
        self.codePointSize = codePointSize
        self.lineHeightMultiplier = lineHeightMultiplier
    }

    /// The typography used by the original Markdown reader.
    public static let earbuds = MarkdownEditorTheme(
        bodyPointSize: 16,
        listPointSize: 17,
        heading1PointSize: 26,
        heading2PointSize: 23,
        heading3PointSize: 19,
        heading4PointSize: 17,
        codePointSize: 13,
        lineHeightMultiplier: 1.56
    )
}

public enum MarkdownEditorError: LocalizedError {
    case resourceMissing(String)
    case notReady
    case javaScript(String)
    case invalidBridgeMessage

    public var errorDescription: String? {
        switch self {
        case .resourceMissing(let name):
            return "MarkdownEditor 缺少资源：\(name)"
        case .notReady:
            return "MarkdownEditor 尚未完成加载。"
        case .javaScript(let message):
            return "MarkdownEditor 脚本执行失败：\(message)"
        case .invalidBridgeMessage:
            return "MarkdownEditor 收到了无法识别的页面消息。"
        }
    }
}

@MainActor
public protocol MarkdownEditorViewDelegate: AnyObject {
    func markdownEditorDidBecomeReady(_ editor: MarkdownEditorView)
    func markdownEditor(_ editor: MarkdownEditorView, didChangeMarkdown markdown: String)
    func markdownEditor(_ editor: MarkdownEditorView, didSelectBlockStyle style: MarkdownBlockStyle)
    func markdownEditorDidBeginEditing(_ editor: MarkdownEditorView)
    func markdownEditorDidEndEditing(_ editor: MarkdownEditorView)
    func markdownEditorDidRequestEditing(_ editor: MarkdownEditorView)
    func markdownEditor(_ editor: MarkdownEditorView, didTapLink url: URL)
    func markdownEditorDidTapDone(_ editor: MarkdownEditorView)
    func markdownEditor(_ editor: MarkdownEditorView, didFail error: MarkdownEditorError)
}

public extension MarkdownEditorViewDelegate {
    func markdownEditorDidBecomeReady(_ editor: MarkdownEditorView) {}
    func markdownEditor(_ editor: MarkdownEditorView, didChangeMarkdown markdown: String) {}
    func markdownEditor(_ editor: MarkdownEditorView, didSelectBlockStyle style: MarkdownBlockStyle) {}
    func markdownEditorDidBeginEditing(_ editor: MarkdownEditorView) {}
    func markdownEditorDidEndEditing(_ editor: MarkdownEditorView) {}
    func markdownEditorDidRequestEditing(_ editor: MarkdownEditorView) {}
    func markdownEditor(_ editor: MarkdownEditorView, didTapLink url: URL) {}
    func markdownEditorDidTapDone(_ editor: MarkdownEditorView) {}
    func markdownEditor(_ editor: MarkdownEditorView, didFail error: MarkdownEditorError) {}
}

internal struct MarkdownEditorThemePayload {
    let bodySize: CGFloat
    let listSize: CGFloat
    let heading1Size: CGFloat
    let heading2Size: CGFloat
    let heading3Size: CGFloat
    let heading4Size: CGFloat
    let inlineCodeSize: CGFloat
    let codeSize: CGFloat
    let tableHeaderSize: CGFloat
    let lineHeight: CGFloat
    let isDark: Bool
    let backgroundColor: String
    let contentTopInset: CGFloat
    let contentLeadingInset: CGFloat
    let contentBottomInset: CGFloat
    let contentTrailingInset: CGFloat

    init(
        theme: MarkdownEditorTheme,
        backgroundColor: UIColor,
        contentInsets: NSDirectionalEdgeInsets,
        traits: UITraitCollection
    ) {
        func scaled(_ value: CGFloat, style: UIFont.TextStyle) -> CGFloat {
            UIFontMetrics(forTextStyle: style).scaledValue(for: value, compatibleWith: traits)
        }

        bodySize = scaled(theme.bodyPointSize, style: .body)
        listSize = scaled(theme.listPointSize, style: .body)
        heading1Size = scaled(theme.heading1PointSize, style: .largeTitle)
        heading2Size = scaled(theme.heading2PointSize, style: .title2)
        heading3Size = scaled(theme.heading3PointSize, style: .title2)
        heading4Size = scaled(theme.heading4PointSize, style: .headline)
        inlineCodeSize = scaled(max(theme.bodyPointSize - 1, 11), style: .body)
        codeSize = scaled(theme.codePointSize, style: .body)
        tableHeaderSize = scaled(max(theme.bodyPointSize - 1, 11), style: .body)
        lineHeight = theme.lineHeightMultiplier
        isDark = traits.userInterfaceStyle == .dark
        self.backgroundColor = Self.cssColor(backgroundColor, traits: traits)
        contentTopInset = contentInsets.top
        contentLeadingInset = contentInsets.leading
        contentBottomInset = contentInsets.bottom
        contentTrailingInset = contentInsets.trailing
    }

    var javaScriptArguments: [String: Any] {
        [
            "theme": [
                "bodySize": bodySize,
                "listSize": listSize,
                "heading1Size": heading1Size,
                "heading2Size": heading2Size,
                "heading3Size": heading3Size,
                "heading4Size": heading4Size,
                "inlineCodeSize": inlineCodeSize,
                "codeSize": codeSize,
                "tableHeaderSize": tableHeaderSize,
                "lineHeight": lineHeight,
                "isDark": isDark,
                "backgroundColor": backgroundColor,
                "contentTopInset": contentTopInset,
                "contentLeadingInset": contentLeadingInset,
                "contentBottomInset": contentBottomInset,
                "contentTrailingInset": contentTrailingInset,
            ],
        ]
    }

    private static func cssColor(_ color: UIColor, traits: UITraitCollection) -> String {
        let resolvedColor = color.resolvedColor(with: traits)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(
                format: "rgba(%d, %d, %d, %.4f)",
                Int(round(red * 255)),
                Int(round(green * 255)),
                Int(round(blue * 255)),
                alpha
            )
        }

        var white: CGFloat = 0
        if resolvedColor.getWhite(&white, alpha: &alpha) {
            let component = Int(round(white * 255))
            return String(
                format: "rgba(%d, %d, %d, %.4f)",
                component,
                component,
                component,
                alpha
            )
        }
        return "transparent"
    }
}
