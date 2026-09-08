import XCTest
@testable import MarkdownEditor

@MainActor
final class MarkdownEditorTests: XCTestCase {
    func testCompactBlockStyleSurfaceIsStable() {
        XCTAssertEqual(
            MarkdownBlockStyle.allCases,
            [
                .heading1,
                .heading2,
                .heading3,
                .heading4,
                .paragraph,
                .unorderedList,
                .taskList,
            ]
        )
    }

    func testDefaultsMatchReaderBehavior() {
        let configuration = MarkdownEditorConfiguration()

        XCTAssertFalse(configuration.isEditable)
        XCTAssertTrue(configuration.showsFormattingBar)
        XCTAssertTrue(configuration.allowsTaskInteractionInReadMode)
        XCTAssertEqual(configuration.theme.bodyPointSize, 16)
        XCTAssertEqual(configuration.theme.heading1PointSize, 26)
        XCTAssertEqual(configuration.contentInsets.top, 24)
        XCTAssertEqual(configuration.contentInsets.leading, 20)
        XCTAssertEqual(configuration.contentInsets.bottom, 56)
        XCTAssertEqual(configuration.contentInsets.trailing, 20)
    }

    func testHostCanCustomizeSurfaceAndDocumentInsets() {
        let insets = NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        let configuration = MarkdownEditorConfiguration(
            backgroundColor: .systemGroupedBackground,
            contentInsets: insets
        )

        XCTAssertEqual(configuration.backgroundColor, .systemGroupedBackground)
        XCTAssertEqual(configuration.contentInsets.top, 1)
        XCTAssertEqual(configuration.contentInsets.leading, 2)
        XCTAssertEqual(configuration.contentInsets.bottom, 3)
        XCTAssertEqual(configuration.contentInsets.trailing, 4)
    }

    func testEditorAndRuntimeResourcesAreBundled() throws {
        let htmlURL = try XCTUnwrap(MarkdownEditorResources.editorHTMLURL)
        let root = htmlURL.deletingLastPathComponent()
        let requiredPaths = [
            "bridge.js",
            "editor.css",
            "VERSION",
            "LICENSE",
            "dist/index.css",
            "dist/index.min.js",
            "dist/js/lute/lute.min.js",
            "dist/js/i18n/zh_CN.js",
            "dist/js/icons/ant.js",
            "dist/css/content-theme/earbuds.css",
        ]

        for path in requiredPaths {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: root.appendingPathComponent(path).path),
                "Missing bundled resource: \(path)"
            )
        }

        let bridge = try String(
            contentsOf: root.appendingPathComponent("bridge.js"),
            encoding: .utf8
        )
        let html = try String(contentsOf: htmlURL, encoding: .utf8)
        let editorCSS = try String(
            contentsOf: root.appendingPathComponent("editor.css"),
            encoding: .utf8
        )
        let themeCSS = try String(
            contentsOf: root.appendingPathComponent("dist/css/content-theme/earbuds.css"),
            encoding: .utf8
        )

        XCTAssertFalse(bridge.contains("unpkg.com"))
        XCTAssertFalse(bridge.contains("localStorage"))
        XCTAssertTrue(html.contains("id=\"vditorLuteScript\""))
        XCTAssertTrue(html.contains("dist/js/icons/ant.js"))
        XCTAssertFalse(editorCSS.contains(":has("))
        XCTAssertFalse(themeCSS.contains(":has("))
    }

    func testEditorRoundTripsCoreMarkdownThroughBundledRuntime() async throws {
        let ready = expectation(description: "Vditor becomes ready")
        let editor = MarkdownEditorView()
        editor.onReady = { ready.fulfill() }

        let source = """
        # 标题

        ## 小节

        - 项目
        - [ ] 待办
        - [x] 完成
        """
        editor.setMarkdown(source)

        await fulfillment(of: [ready], timeout: 5)

        let exported = try await withCheckedThrowingContinuation { continuation in
            editor.getMarkdown { continuation.resume(with: $0) }
        }

        XCTAssertTrue(exported.contains("# 标题"))
        XCTAssertTrue(exported.contains("## 小节"))
        XCTAssertTrue(exported.contains("- 项目"))
        XCTAssertTrue(exported.contains("- [ ] 待办"))
        XCTAssertTrue(exported.contains("- [x] 完成"), "Exported Markdown:\n\(exported)")
    }
}
