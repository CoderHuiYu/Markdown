//
//  ViewController.swift
//  Markdown
//
//  Created by admin on 2026/9/7.
//

import UIKit
import MarkdownView
import SnapKit

final class ViewController: UIViewController {

    private enum Document {
        static let resourceName = "7月29日 云同步功能逻辑与AI联动规则"
        static let fileExtension = "md"
    }

    private enum DocumentLoadingError: Error {
        case resourceNotFound
        case emptyDocument
    }

    private lazy var markdownView: MarkdownView = {
        let markdownView = MarkdownView(
            css: Self.readerCSS,
            plugins: [MarkdownTaskListPlugin.javascript],
            styled: true
        )
        markdownView.backgroundColor = .systemBackground
        markdownView.isScrollEnabled = true
        markdownView.onRendered = { [weak self] _ in
            self?.activityIndicator.stopAnimating()
        }
        markdownView.onTouchLink = { request in
            guard let url = request.url else { return false }
            UIApplication.shared.open(url)
            return false
        }
        return markdownView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.accessibilityLabel = "正在加载会议纪要"
        return activityIndicator
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        loadDocument()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        view.addSubview(markdownView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)

        markdownView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }

        errorLabel.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(32)
        }
    }

    private func loadDocument() {
        activityIndicator.startAnimating()

        do {
            guard let url = Bundle.main.url(
                forResource: Document.resourceName,
                withExtension: Document.fileExtension
            ) else {
                throw DocumentLoadingError.resourceNotFound
            }

            let markdown = try String(contentsOf: url, encoding: .utf8)
            guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DocumentLoadingError.emptyDocument
            }

            errorLabel.isHidden = true
            markdownView.isHidden = false
            markdownView.render(markdown: markdown)
        } catch {
            activityIndicator.stopAnimating()
            markdownView.isHidden = true
            errorLabel.text = "无法加载会议纪要。\n请确认 Markdown 文件已加入应用 Target。"
            errorLabel.isHidden = false
            assertionFailure("Failed to load bundled Markdown document: \(error)")
        }
    }

    private static let readerCSS = """
    :root {
        color-scheme: light dark;
        --reader-background: #FFFFFF;
        --reader-text: #1C1C1E;
        --reader-secondary: #F2F2F7;
        --reader-muted: #636366;
        --reader-border: #D1D1D6;
        --reader-control-border: #8E8E93;
        --reader-link: #007AFF;
        --reader-code: #F2F2F7;
        --reader-font: "PingFang SC", "Hiragino Sans", -apple-system, sans-serif;
    }

    html {
        background: var(--reader-background);
        -webkit-text-size-adjust: 100%;
    }

    body {
        margin: 0;
        padding: 24px 20px 56px;
        background: var(--reader-background);
        color: var(--reader-text);
        font: -apple-system-body;
        font-family: var(--reader-font);
        line-height: 1.7;
        overflow-wrap: anywhere;
    }

    .container {
        width: 100%;
        max-width: 760px;
        margin: 0 auto;
        padding: 0;
    }

    h1, h2, h3, h4, h5, h6 {
        color: var(--reader-text);
        font-weight: 700;
        line-height: 1.25;
    }

    h1 {
        margin: 0 0 22px;
        font: -apple-system-title1;
        font-family: var(--reader-font);
        font-weight: 750;
        letter-spacing: -0.02em;
    }

    h2 {
        margin: 36px 0 14px;
        padding-bottom: 8px;
        border-bottom: 1px solid var(--reader-border);
        font: -apple-system-title2;
        font-family: var(--reader-font);
        font-weight: 700;
        letter-spacing: -0.015em;
    }

    h3 {
        margin: 28px 0 10px;
        font: -apple-system-title3;
        font-family: var(--reader-font);
        font-weight: 700;
    }

    p, ul, ol, blockquote, table {
        margin-top: 0;
        margin-bottom: 16px;
    }

    ul, ol {
        padding-left: 1.4em;
    }

    li + li {
        margin-top: 7px;
    }

    .task-list-item {
        list-style: none;
    }

    .task-list-control {
        display: inline-flex;
        width: 44px;
        height: 44px;
        margin: -10px 2px -10px -12px;
        align-items: center;
        justify-content: center;
        vertical-align: middle;
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
    }

    .task-list-item-checkbox {
        position: absolute;
        width: 1px;
        height: 1px;
        overflow: hidden;
        clip-path: inset(50%);
    }

    .task-list-box {
        position: relative;
        box-sizing: border-box;
        width: 22px;
        height: 22px;
        border: 2px solid var(--reader-control-border);
        border-radius: 6px;
        background: var(--reader-background);
    }

    .task-list-item-checkbox:checked + .task-list-box {
        border-color: var(--reader-link);
        background: var(--reader-link);
    }

    .task-list-item-checkbox:checked + .task-list-box::after {
        position: absolute;
        top: 2px;
        left: 6px;
        width: 5px;
        height: 10px;
        border: solid var(--reader-background);
        border-width: 0 2px 2px 0;
        content: "";
        transform: rotate(45deg);
    }

    .task-list-item-checkbox:focus-visible + .task-list-box {
        outline: 2px solid var(--reader-link);
        outline-offset: 3px;
    }

    blockquote {
        margin-left: 0;
        margin-right: 0;
        padding: 16px 18px;
        border: 0;
        border-radius: 14px;
        background: var(--reader-secondary);
        color: var(--reader-muted);
        font: -apple-system-subheadline;
        font-family: var(--reader-font);
        line-height: 1.6;
    }

    blockquote p:last-child {
        margin-bottom: 0;
    }

    strong {
        color: var(--reader-text);
        font-weight: 700;
    }

    a {
        color: var(--reader-link);
        text-decoration: underline;
        text-underline-offset: 0.15em;
    }

    table {
        display: block;
        width: 100%;
        overflow-x: auto;
        border-collapse: collapse;
        border-radius: 12px;
        -webkit-overflow-scrolling: touch;
    }

    th, td {
        min-width: 112px;
        padding: 11px 12px;
        border: 1px solid var(--reader-border);
        text-align: left;
        vertical-align: top;
    }

    th {
        background: var(--reader-secondary);
        font-weight: 700;
    }

    code, pre {
        border: 0;
        background: var(--reader-code);
        color: var(--reader-text);
    }

    code {
        padding: 0.12em 0.35em;
        border-radius: 6px;
    }

    pre {
        padding: 14px;
        border-radius: 12px;
        overflow-x: auto;
    }

    img {
        max-width: 100%;
        height: auto;
        border-radius: 12px;
    }

    @media (min-width: 768px) {
        body {
            padding: 40px 44px 72px;
        }
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --reader-background: #000000;
            --reader-text: #F2F2F7;
            --reader-secondary: #1C1C1E;
            --reader-muted: #AEAEB2;
            --reader-border: #38383A;
            --reader-control-border: #8E8E93;
            --reader-link: #64D2FF;
            --reader-code: #1C1C1E;
        }
    }
    """

}
