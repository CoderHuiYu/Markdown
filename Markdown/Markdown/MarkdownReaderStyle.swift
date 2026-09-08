//
//  MarkdownReaderStyle.swift
//  Markdown
//

import UIKit

enum MarkdownReaderStyle {

    private enum Theme {
        static let fontBody: CGFloat = 16
        static let fontList: CGFloat = 17
        static let fontH1: CGFloat = 26
        static let fontH2: CGFloat = 23
        static let fontH3: CGFloat = 19
        static let fontH4: CGFloat = 17
        static let fontCode: CGFloat = 13
        static let lineHeightMultiplier: CGFloat = 1.56
    }

    static func make(traits: UITraitCollection) -> String {
        guard let url = Bundle.main.url(forResource: "MarkdownReader", withExtension: "css"),
              let template = try? String(contentsOf: url, encoding: .utf8) else {
            assertionFailure("MarkdownReader.css is missing from the app bundle.")
            return ""
        }

        func scaled(_ value: CGFloat, for style: UIFont.TextStyle) -> CGFloat {
            UIFontMetrics(forTextStyle: style).scaledValue(for: value, compatibleWith: traits)
        }

        func px(_ value: CGFloat) -> String {
            String(format: "%g", Double(value))
        }

        let replacements = [
            "{{BODY_SIZE}}": px(scaled(Theme.fontBody, for: .body)),
            "{{LIST_SIZE}}": px(scaled(Theme.fontList, for: .body)),
            "{{H1_SIZE}}": px(scaled(Theme.fontH1, for: .largeTitle)),
            "{{H2_SIZE}}": px(scaled(Theme.fontH2, for: .title2)),
            "{{H3_SIZE}}": px(scaled(Theme.fontH3, for: .title2)),
            "{{H4_SIZE}}": px(scaled(Theme.fontH4, for: .headline)),
            "{{INLINE_CODE_SIZE}}": px(Theme.fontBody - 1),
            "{{CODE_SIZE}}": px(Theme.fontCode),
            "{{TABLE_HEADER_SIZE}}": px(scaled(Theme.fontBody, for: .body) - 1),
            "{{LINE_HEIGHT}}": px(Theme.lineHeightMultiplier)
        ]

        return replacements.reduce(template) { css, replacement in
            css.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }
}
