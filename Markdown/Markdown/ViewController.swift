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

    private var markdown = ""

    private lazy var markdownView: MarkdownView = {
        let markdownView = MarkdownView(
            css: self.makeReaderCSS(traits: self.traitCollection),
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }
        markdownView.reconfigure(
            css: makeReaderCSS(traits: traitCollection),
            plugins: [MarkdownTaskListPlugin.javascript],
            styled: true
        )
        if !markdown.isEmpty {
            markdownView.render(markdown: markdown)
        }
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
            self.markdown = markdown
            markdownView.render(markdown: markdown)
        } catch {
            activityIndicator.stopAnimating()
            markdownView.isHidden = true
            errorLabel.text = "无法加载会议纪要。\n请确认 Markdown 文件已加入应用 Target。"
            errorLabel.isHidden = false
            assertionFailure("Failed to load bundled Markdown document: \(error)")
        }
    }

    private func makeReaderCSS(traits: UITraitCollection) -> String {
        func scaled(_ value: CGFloat, for style: UIFont.TextStyle) -> CGFloat {
            UIFontMetrics(forTextStyle: style).scaledValue(for: value, compatibleWith: traits)
        }
        func px(_ value: CGFloat) -> String { String(format: "%g", Double(value)) }

        let bodySize = scaled(Theme.fontBody, for: .body)
        let listSize = scaled(Theme.fontList, for: .body)
        let h1Size = scaled(Theme.fontH1, for: .largeTitle)
        let h2Size = scaled(Theme.fontH2, for: .title2)
        let h3Size = scaled(Theme.fontH3, for: .title2)
        let h4Size = scaled(Theme.fontH4, for: .headline)
        let inlineCodeSize = Theme.fontBody - 1
        let codeSize = Theme.fontCode
        let lineHeight = Theme.lineHeightMultiplier

        return """
    :root {
        color-scheme: light dark;
        --md-text: #000000;
        --md-bg: #FFFFFF;
        --md-secondary: rgba(60, 60, 67, 0.60);
        --md-fill: rgba(118, 118, 128, 0.12);
        --md-th-bg: rgba(3, 0, 153, 0.02);
        --md-link: #007AFF;
        --md-quote-line: rgba(115, 121, 140, 0.40);
        --md-bullet: rgba(4, 4, 4, 0.75);
        --md-separator: rgba(0, 0, 0, 0.09);
        --md-check: #01BC4A;
        --md-font: "PingFang SC", "Hiragino Sans", -apple-system, sans-serif;
    }

    html {
        background: var(--md-bg);
        -webkit-text-size-adjust: 100%;
    }

    body {
        margin: 0;
        padding: 24px 20px 56px;
        background: var(--md-bg);
        color: var(--md-text);
        font-family: var(--md-font);
        font-size: \(px(bodySize))px;
        line-height: \(px(lineHeight));
        overflow-wrap: anywhere;
    }

    .container {
        display: flex;
        flex-direction: column;
        align-items: stretch;
        width: 100%;
        max-width: 760px;
        margin: 0 auto;
        padding: 0;
    }

    .container > * {
        flex: 0 0 auto;
    }

    /* ===== 标题：固定字号 + 底部渐变装饰条 ===== */
    h1, h2, h3, h4, h5, h6 {
        position: relative;
        align-self: flex-start;
        width: fit-content;
        max-width: 100%;
        color: var(--md-text);
        font-family: var(--md-font);
        font-weight: 700;
        line-height: 1.18;
    }

    h1 { font-size: \(px(h1Size))px; }
    h2 { font-size: \(px(h2Size))px; }
    h3 { font-size: \(px(h3Size))px; }
    h4, h5, h6 { font-size: \(px(h4Size))px; }

    h2, h3 { isolation: isolate; }

    h2::after, h3::after {
        content: "";
        position: absolute;
        left: 0;
        right: 0;
        bottom: -1px;
        display: block;
        border-radius: 4px;
        pointer-events: none;
        z-index: -1;   /* 渐变条置于文字下层 */
    }

    h2::after { height: 9px; }
    h2:nth-of-type(3n+1)::after {
        background: linear-gradient(90deg, rgba(118,123,255,.30), rgba(189,124,255,0));
    }
    h2:nth-of-type(3n+2)::after {
        background: linear-gradient(90deg, rgba(255,121,121,.30), rgba(255,205,125,0));
    }
    h2:nth-of-type(3n)::after {
        background: linear-gradient(90deg, rgba(50,255,50,.30), rgba(98,255,213,0));
    }

    h3::after {
        height: 6px;
        background: linear-gradient(90deg, rgba(31,56,139,.15), rgba(31,56,139,0));
    }

    /* ===== 间距体系（对齐原生 MarkdownTheme）=====
       flex 列布局 margin 不折叠；相邻间距 = 前.bottom + 后.top + 7·类型不同 + 7·层级升高 */
    #contents > p { margin-top: 4px; margin-bottom: 4px; font-size: \(px(bodySize))px; line-height: \(px(lineHeight)); }
    #contents > ol,
    #contents > ul:not(:has(> li.task-list-item)) { margin-top: 4px; margin-bottom: 4px; font-size: \(px(listSize))px; line-height: \(px(lineHeight)); }
    #contents > ul:has(> li.task-list-item) { margin-top: 9px; margin-bottom: 9px; font-size: \(px(bodySize))px; line-height: \(px(lineHeight)); }
    #contents > h1 { margin-top: 21px; margin-bottom: 7px; }
    #contents > h2 { margin-top: 14px; margin-bottom: 7px; }
    #contents > h3 { margin-top: 7px; margin-bottom: 7px; }
    #contents > h4, #contents > h5, #contents > h6 { margin-top: 4px; margin-bottom: 4px; }
    #contents > blockquote { margin-top: 4px; margin-bottom: 4px; }
    #contents > pre { margin-top: 0; margin-bottom: 12px; }
    #contents > table { margin-top: 14px; margin-bottom: 14px; }

    /* 附加 +7（类型不同）+7（层级升高）*/
    #contents > :is(h1, h2, h3, h4, h5, h6, blockquote, pre, table) + p { margin-top: 11px; }

    #contents > :is(p, h1, h2, h3, h4, h5, h6, blockquote, pre, table) + ol,
    #contents > :is(p, h1, h2, h3, h4, h5, h6, blockquote, pre, table) + ul:not(:has(> li.task-list-item)) { margin-top: 11px; }

    #contents > :is(p, h1, h2, h3, h4, h5, h6, blockquote, pre, table) + ul:has(> li.task-list-item) { margin-top: 16px; }

    #contents > :is(p, ol, ul, h1, h2, h3, blockquote, pre, table) + h4,
    #contents > :is(p, ol, ul, h1, h2, h3, blockquote, pre, table) + h5,
    #contents > :is(p, ol, ul, h1, h2, h3, blockquote, pre, table) + h6 { margin-top: 11px; }

    #contents > :is(h1, h2, blockquote, pre, table) + h3 { margin-top: 14px; }
    #contents > :is(p, ol, ul, h4, h5, h6) + h3 { margin-top: 21px; }

    #contents > :is(h1, blockquote, pre, table) + h2 { margin-top: 21px; }
    #contents > :is(p, ol, ul, h3, h4, h5, h6) + h2 { margin-top: 28px; }

    #contents > :is(blockquote, pre, table) + h1 { margin-top: 28px; }
    #contents > :is(p, ol, ul, h2, h3, h4, h5, h6) + h1 { margin-top: 35px; }

    #contents > :is(p, ol, ul, h1, h2, h3, h4, h5, h6, pre, table) + blockquote { margin-top: 11px; }

    #contents > :is(p, ol, ul, h1, h2, h3, h4, h5, h6, blockquote, table) + pre { margin-top: 7px; }

    #contents > :is(p, ol, ul, h1, h2, h3, h4, h5, h6, blockquote, pre) + table { margin-top: 21px; }

    /* ===== 列表：缩进 + bullet ===== */
    #contents > ul, #contents > ol { padding-left: 20px; }
    #contents > ul:has(> li.task-list-item) { padding-left: 0; }
    #contents > ul ul, #contents > ul ol, #contents > ol ul, #contents > ol ol { padding-left: 20px; margin-top: 8px; font-size: \(px(bodySize))px; }

    #contents > ul { list-style: disc; }
    #contents > ul ul { list-style: circle; }
    #contents > ul > li::marker, #contents > ul ul > li::marker { color: var(--md-bullet); }

    li + li { margin-top: 8px; }
    li:has(> ul) + li, li:has(> ol) + li { margin-top: 15px; }

    /* ===== 引用块：左侧竖线 ===== */
    #contents > blockquote {
        padding: 0 0 0 18px;
        border-left: 2px solid var(--md-quote-line);
        color: var(--md-secondary);
        font-size: \(px(bodySize))px;
        line-height: \(px(lineHeight));
    }
    blockquote p { margin-top: 0; margin-bottom: 0; }
    strong, b { font-weight: 700; }

    /* ===== 链接 ===== */
    a {
        color: var(--md-link);
        text-decoration: underline;
        text-underline-offset: 0.15em;
    }

    /* ===== 代码 ===== */
    code {
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: \(px(inlineCodeSize))px;
        background: var(--md-fill);
        color: var(--md-text);
        padding: 0;
        border-radius: 0;
    }

    pre {
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: \(px(codeSize))px;
        background: var(--md-fill);
        color: var(--md-text);
        padding: 10px;
        border-radius: 6px;
        overflow-x: auto;
        line-height: 1.54;
        white-space: pre;
        word-break: normal;
    }

    /* ===== 任务列表 ===== */
    .task-list-item {
        position: relative;
        list-style: none;
        padding-left: 32px;   /* 24 块 + 8 间距 */
    }

    .task-list-control {
        position: absolute;
        left: 0;
        top: 0;
        display: inline-flex;
        width: 24px;
        height: 24px;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
    }

    .task-list-control::before {
        content: "";
        position: absolute;
        top: -10px;
        right: -10px;
        bottom: -10px;
        left: -10px;
    }

    /* 勾选后：文字 40% + 删除线 */
    .task-list-item:has(.task-list-item-checkbox:checked) {
        color: rgba(0, 0, 0, 0.40);
        text-decoration: line-through;
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
        display: inline-flex;      /* flex 居中 svg：锚点是内容区中心，恒等于方框中心 */
        align-items: center;
        justify-content: center;
        box-sizing: border-box;
        width: 20px;
        height: 20px;
        border: 1.8px solid rgba(0, 0, 0, 0.09);
        border-radius: 6px;
        background: var(--md-bg);
        will-change: transform;   /* 合成层常驻，避免 pop 动画结束后释放层导致子元素（对勾）重排跳位 */
        transition: border-color 0.25s ease;
    }

    /* 绿色填充层：覆盖整个方框（含描边区），勾选时从中心扩散；圆角与方框一致避免露出底色 */
    .task-list-box::before {
        content: "";
        position: absolute;
        inset: -1.8px;
        border-radius: 6px;
        background: var(--md-check);
        transform: scale(0);
        transform-origin: center;
        transition: transform 0.2s ease;
    }

    /* 对勾：SVG 描边，笔画书写动画（dash 用整数 16，动画终态由 forwards 常驻，避免结束帧跳变）
       不用 absolute（iOS WebKit 对替换元素负偏移/拉伸尺寸推导不可靠，会整体偏移）；
       作为 flex item 以方框内容区中心为锚居中——内容区中心恒等于方框中心，
       任何渲染路径下勾都在方框正中心；translateZ(0) 合成层保证动画前后一致 */
    .task-list-check {
        display: block;
        flex: none;        /* 不参与 flex 伸缩，保持 20x20 */
        width: 20px;       /* 显式整数尺寸，与 viewBox 1:1 */
        height: 20px;
        fill: none;
        stroke: #FFFFFF;
        stroke-width: 2;
        stroke-linecap: round;
        stroke-linejoin: round;
        stroke-dasharray: 16;
        stroke-dashoffset: 16;
        opacity: 0;
        pointer-events: none;
        transform: translateZ(0);
        will-change: stroke-dashoffset;
        transition: stroke-dashoffset 0.18s ease, opacity 0.18s ease;
    }

    .task-list-item-checkbox:checked + .task-list-box {
        border-color: var(--md-check);
        animation: md-task-pop 0.9s;
    }

    .task-list-item-checkbox:checked + .task-list-box::before {
        transform: scale(1);
        animation: md-task-fill 0.9s cubic-bezier(0.22, 0.9, 0.36, 1);
    }

    .task-list-item-checkbox:checked + .task-list-box .task-list-check {
        /* 只声明动画，不设静态终值：delay 期间 underlying 保持基础值
           （dashoffset 16 / opacity 0，勾隐藏），动画启动时 from=16→0
           书写动画才可见；终态由 forwards 常驻，取消勾选时由 transition 平滑回落 */
        animation: md-task-draw 0.4s cubic-bezier(0.22, 1, 0.36, 1) 0.1s forwards;  /* 缓出：越往后速度越慢 */
    }

    @keyframes md-task-pop {
        0% { transform: scale(1); animation-timing-function: cubic-bezier(0.2, 0.8, 0.4, 1); }
        25% { transform: scale(1.3); animation-timing-function: cubic-bezier(0.34, 1.56, 0.64, 1); }
        48% { transform: scale(1); }
        100% { transform: scale(1); }
    }

    @keyframes md-task-fill {
        0% { transform: scale(0); }
        40% { transform: scale(1); }
        100% { transform: scale(1); }
    }

    @keyframes md-task-draw {
        /* 显式双帧：WebKit 对仅 to 单帧动画的 timing 曲线应用不可靠（会退化成匀速）；
           双帧 + 缓出贝塞尔曲线确保书写“起笔快、收笔慢” */
        0% { stroke-dashoffset: 16; opacity: 0; }
        100% { stroke-dashoffset: 0; opacity: 1; }
    }

    .task-list-item-checkbox:focus-visible + .task-list-box {
        outline: 2px solid var(--md-link);
        outline-offset: 3px;
    }

    /* ===== 表格 =====
       注意：markdown-it 输出 <table class="table">，MarkdownView 内置 Bootstrap 的
       .table 规则特异性更高（表头 2px 底线、每行 border-top），必须用
       #contents .table 级别选择器覆盖。 */
    #contents table.table {
        display: block;
        width: 100%;
        overflow-x: auto;
        border-collapse: separate;
        border-spacing: 0;
        border: 1px solid var(--md-separator);
        border-radius: 16px;
        -webkit-overflow-scrolling: touch;
    }

    #contents .table th, #contents .table td {
        min-width: 112px;
        padding: 11px 12px;
        border-top: none;
        border-right: 1px solid var(--md-separator);
        border-bottom: 1px solid var(--md-separator);
        text-align: left;
        vertical-align: top;
        line-height: inherit;
        background: transparent;
    }

    #contents .table th {
        background: var(--md-th-bg);
        font-size: \(px(bodySize - 1))px;   /* 比表格内容小 1 号 */
        font-weight: 700;
        border-bottom: 1px solid var(--md-separator);
    }

    #contents .table th:last-child, #contents .table td:last-child {
        border-right: none;
    }

    #contents .table tr:last-child td {
        border-bottom: none;
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
            --md-text: #FFFFFF;
            --md-bg: #000000;
            --md-secondary: rgba(235, 235, 245, 0.60);
            --md-fill: rgba(118, 118, 128, 0.24);
            --md-th-bg: rgba(3, 0, 153, 0.06);
            --md-link: #0A84FF;
            --md-bullet: rgba(242, 242, 247, 0.75);
            --md-separator: rgba(255, 255, 255, 0.12);
        }
        .task-list-box {
            border-color: rgba(255, 255, 255, 0.12);
        }
        .task-list-item:has(.task-list-item-checkbox:checked) {
            color: rgba(255, 255, 255, 0.40);
        }
    }
    """
    }
}
