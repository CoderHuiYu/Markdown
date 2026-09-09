import UIKit
import WebKit
import XCTest
@testable import MarkdownEditor

@MainActor
final class MarkdownEditorScrollingTests: XCTestCase {
    func testEmbeddedDocumentShrinksAndLeavesVerticalScrollingToHost() async throws {
        let host = EmbeddedEditorHost()
        defer { host.close() }
        let ready = expectation(description: "Editor ready")
        host.editor.onReady = { ready.fulfill() }
        let source = (1...45).map { "## 小节 \($0)\n\n正文内容，用于验证长笔记和下方思维导图的滚动布局。\n\n- 项目\n  - 二级项目" }
            .joined(separator: "\n\n")
        host.editor.setMarkdown(source)
        await fulfillment(of: [ready], timeout: 8)
        try await waitUntil { host.editor.contentHeight > 2_000 }
        let longHeight = host.editor.contentHeight

        let webView = try XCTUnwrap(host.editor.subviews.compactMap { $0 as? WKWebView }.first)
        let overflow = try await webView.evaluateJavaScript(
            "getComputedStyle(document.querySelector('.vditor-wysiwyg')).overflowY"
        ) as? String
        XCTAssertEqual(overflow, "visible", "The HTML editor must not keep a nested vertical scroller")

        for index in 0..<12 {
            host.scrollView.contentOffset.y = index.isMultiple(of: 2) ? 500 : 1_000
            host.scrollView.frame.size.height = index.isMultiple(of: 2) ? 500 : 700
            host.controller.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(host.editor.contentHeight, longHeight, accuracy: 1)

        host.editor.setMarkdown("只有一行正文。")
        try await waitUntil { host.editor.contentHeight < 200 }
        host.controller.view.layoutIfNeeded()
        XCTAssertLessThan(host.editor.contentHeight, longHeight)
        XCTAssertEqual(host.footer.frame.minY, host.editor.frame.maxY + 24, accuracy: 1)
        XCTAssertLessThan(host.footer.frame.maxY, 500, "The mind-map footer must follow shortened content")
    }

    func testViewportEventBurstDoesNotFloodTheNativeBridge() async throws {
        let host = EmbeddedEditorHost()
        defer { host.close() }
        let ready = expectation(description: "Editor ready")
        host.editor.onReady = { ready.fulfill() }
        host.editor.setMarkdown("# 标题\n\n- [ ] 待办\n  - 二级条目")
        await fulfillment(of: [ready], timeout: 8)
        try await Task.sleep(nanoseconds: 400_000_000)

        let webView = try XCTUnwrap(host.editor.subviews.compactMap { $0 as? WKWebView }.first)
        let controller = webView.configuration.userContentController
        let recorder = HeightMessageRecorder(editor: host.editor)
        controller.removeScriptMessageHandler(forName: "markdownEditor")
        controller.add(recorder, name: "markdownEditor")
        defer { controller.removeScriptMessageHandler(forName: "markdownEditor") }

        _ = try await webView.evaluateJavaScript("""
        for (let index = 0; index < 120; index += 1) {
            window.visualViewport.dispatchEvent(new Event('resize'));
        }
        """)
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertLessThanOrEqual(recorder.heightCount, 1, "Unchanged layout must not produce one native message per viewport event")
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        for _ in 0..<60 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Content height did not settle", file: file, line: line)
    }
}

@MainActor
private final class EmbeddedEditorHost {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    let controller = UIViewController()
    let scrollView = UIScrollView()
    let footer = UIView()
    let editor = MarkdownEditorView(configuration: .init(
        contentInsets: .init(top: 0, leading: 26, bottom: 0, trailing: 26)
    ))

    init() {
        window.rootViewController = controller
        controller.loadViewIfNeeded()
        scrollView.frame = controller.view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.addSubview(scrollView)
        editor.isScrollEnabled = false
        scrollView.addSubview(editor)
        scrollView.addSubview(footer)
        editor.translatesAutoresizingMaskIntoConstraints = false
        footer.translatesAutoresizingMaskIntoConstraints = false
        let height = editor.heightAnchor.constraint(equalToConstant: 1)
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            editor.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            editor.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            height,
            footer.topAnchor.constraint(equalTo: editor.bottomAnchor, constant: 24),
            footer.leadingAnchor.constraint(equalTo: editor.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: editor.trailingAnchor),
            footer.heightAnchor.constraint(equalToConstant: 268),
            footer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])
        editor.onContentHeightChange = { [weak self] value in
            height.constant = max(1, ceil(value))
            self?.controller.view.layoutIfNeeded()
        }
        editor.attachFormattingBar(to: controller.view)
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
    }

    func close() {
        editor.onContentHeightChange = nil
        window.isHidden = true
        window.rootViewController = nil
    }
}

@MainActor
private final class HeightMessageRecorder: NSObject, WKScriptMessageHandler {
    weak var editor: MarkdownEditorView?
    var heightCount = 0

    init(editor: MarkdownEditorView) {
        self.editor = editor
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? [String: Any], body["type"] as? String == "height" {
            heightCount += 1
        }
        editor?.userContentController(userContentController, didReceive: message)
    }
}
