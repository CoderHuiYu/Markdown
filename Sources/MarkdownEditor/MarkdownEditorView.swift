import UIKit
import WebKit

public final class MarkdownEditorView: UIView {
    public weak var delegate: MarkdownEditorViewDelegate?

    public var onReady: (() -> Void)?
    public var onMarkdownChange: ((String) -> Void)?
    public var onSelectionChange: ((MarkdownBlockStyle) -> Void)?
    public var onRequestEditing: (() -> Void)?
    public var onLinkTap: ((URL) -> Void)?
    public var onDone: ((String) -> Void)?
    public var onError: ((MarkdownEditorError) -> Void)?
    public var onContentHeightChange: ((CGFloat) -> Void)?

    public let formattingBar = MarkdownFormattingBar()

    public private(set) var markdown: String = ""
    public private(set) var isReady = false
    public private(set) var selectedBlockStyle: MarkdownBlockStyle = .paragraph
    public private(set) var contentHeight: CGFloat = 0

    public var isEditable: Bool {
        didSet {
            guard oldValue != isEditable else { return }
            applyEditability()
            updateFormattingBarVisibility(animated: true)
        }
    }

    public var isScrollEnabled: Bool {
        get { webView.scrollView.isScrollEnabled }
        set { webView.scrollView.isScrollEnabled = newValue }
    }

    private let configuration: MarkdownEditorConfiguration
    private let messageHandlerName = "markdownEditor"
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    private var hasWebFocus = false
    private var pendingMarkdown: String?
    private var pendingSetCompletions: [(Result<Void, MarkdownEditorError>) -> Void] = []
    private var isSettingMarkdown = false
    private var formattingBarConstraints: [NSLayoutConstraint] = []

    private lazy var scriptMessageProxy = WeakScriptMessageHandler(delegate: self)
    private lazy var webView: WKWebView = makeWebView()

    public init(configuration: MarkdownEditorConfiguration = .init()) {
        self.configuration = configuration
        self.isEditable = configuration.isEditable
        super.init(frame: .zero)
        configureView()
        loadEditorPage()
    }

    public required init?(coder: NSCoder) {
        let configuration = MarkdownEditorConfiguration()
        self.configuration = configuration
        self.isEditable = configuration.isEditable
        super.init(coder: coder)
        configureView()
        loadEditorPage()
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: messageHandlerName)
    }

    public override var intrinsicContentSize: CGSize {
        guard !isScrollEnabled, contentHeight > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let appearanceChanged = previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle
        let contentSizeChanged = previousTraitCollection?.preferredContentSizeCategory
            != traitCollection.preferredContentSizeCategory
        if appearanceChanged || contentSizeChanged {
            applyTheme()
        }
    }

    /// Replaces the document while preserving a safe value until the web editor is ready.
    public func setMarkdown(
        _ markdown: String,
        completion: ((Result<Void, MarkdownEditorError>) -> Void)? = nil
    ) {
        self.markdown = markdown
        pendingMarkdown = markdown

        if let completion {
            pendingSetCompletions.append(completion)
        }

        guard isReady else { return }
        flushPendingMarkdown()
    }

    /// Reads the canonical Markdown produced by Vditor.
    public func getMarkdown(
        completion: @escaping (Result<String, MarkdownEditorError>) -> Void
    ) {
        guard isReady else {
            completion(.failure(.notReady))
            return
        }

        executeJavaScript(
            "return window.MarkdownBridge.getMarkdown();"
        ) { result in
            switch result {
            case .success(let value):
                guard let markdown = value as? String else {
                    completion(.failure(.invalidBridgeMessage))
                    return
                }
                self.markdown = markdown
                completion(.success(markdown))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Applies one of the block styles offered by the native formatting bar.
    public func apply(_ style: MarkdownBlockStyle) {
        guard isEditable, isReady else { return }

        executeJavaScript(
            "return window.MarkdownBridge.applyBlockStyle(style);",
            arguments: ["style": style.rawValue]
        ) { result in
            if case .failure(let error) = result {
                self.report(error)
            }
        }
    }

    public func focus() {
        guard isEditable, isReady else { return }
        executeJavaScript("window.MarkdownBridge.focus();") { result in
            if case .failure(let error) = result {
                self.report(error)
            }
        }
    }

    public func blur() {
        guard isReady else { return }
        executeJavaScript("window.MarkdownBridge.blur();") { result in
            if case .failure(let error) = result {
                self.report(error)
            }
        }
    }

    /// Moves the formatting bar to a host surface while keeping its visibility
    /// driven by this editor. This is useful when the editor is embedded in an
    /// outer scroll view and the bar must still follow the screen keyboard.
    public func attachFormattingBar(to hostView: UIView) {
        installFormattingBar(in: hostView)
    }

    private func configureView() {
        backgroundColor = configuration.backgroundColor
        accessibilityIdentifier = "markdown-editor"

        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        formattingBar.isHidden = true
        formattingBar.alpha = 0
        installFormattingBar(in: self)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.accessibilityLabel = "正在加载 Markdown 编辑器"
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()

        errorLabel.font = .preferredFont(forTextStyle: .body)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .secondaryLabel
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])

        formattingBar.onSelectBlockStyle = { [weak self] style in
            self?.apply(style)
        }
        formattingBar.onDone = { [weak self] in
            self?.finishEditing()
        }
    }

    private func installFormattingBar(in hostView: UIView) {
        NSLayoutConstraint.deactivate(formattingBarConstraints)
        formattingBar.removeFromSuperview()
        hostView.addSubview(formattingBar)
        formattingBar.translatesAutoresizingMaskIntoConstraints = false
        formattingBarConstraints = [
            formattingBar.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            formattingBar.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            formattingBar.bottomAnchor.constraint(equalTo: hostView.keyboardLayoutGuide.topAnchor),
            formattingBar.heightAnchor.constraint(equalToConstant: 54),
        ]
        NSLayoutConstraint.activate(formattingBarConstraints)
    }

    private func makeWebView() -> WKWebView {
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.defaultWebpagePreferences = pagePreferences
        webConfiguration.userContentController.add(scriptMessageProxy, name: messageHandlerName)
        webConfiguration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = configuration.backgroundColor
        webView.underPageBackgroundColor = configuration.backgroundColor
        webView.allowsLinkPreview = false
        webView.scrollView.backgroundColor = configuration.backgroundColor
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.alwaysBounceVertical = true
        webView.accessibilityLabel = "Markdown 笔记"
        return webView
    }

    private func loadEditorPage() {
        guard let htmlURL = MarkdownEditorResources.editorHTMLURL else {
            report(.resourceMissing("Vditor/editor.html"), showInView: true)
            return
        }

        isReady = false
        loadingIndicator.startAnimating()
        errorLabel.isHidden = true
        webView.loadFileURL(
            htmlURL,
            allowingReadAccessTo: htmlURL.deletingLastPathComponent()
        )
    }

    private func configureReadyEditor() {
        applyTheme()
        applyPlaceholder()
        applyEditability()
        flushPendingMarkdown()
    }

    private func flushPendingMarkdown() {
        guard isReady, !isSettingMarkdown, let markdown = pendingMarkdown else { return }
        isSettingMarkdown = true
        pendingMarkdown = nil
        let completions = pendingSetCompletions
        pendingSetCompletions.removeAll()

        executeJavaScript(
            "window.MarkdownBridge.setMarkdown(markdown);",
            arguments: ["markdown": markdown]
        ) { result in
            self.isSettingMarkdown = false

            switch result {
            case .success:
                completions.forEach { $0(.success(())) }
            case .failure(let error):
                completions.forEach { $0(.failure(error)) }
                self.report(error)
            }

            self.flushPendingMarkdown()
        }
    }

    private func applyPlaceholder() {
        guard isReady else { return }
        executeJavaScript(
            "window.MarkdownBridge.setPlaceholder(placeholder);",
            arguments: ["placeholder": configuration.placeholder]
        ) { result in
            if case .failure(let error) = result {
                self.report(error)
            }
        }
    }

    private func applyEditability() {
        guard isReady else { return }
        executeJavaScript(
            "window.MarkdownBridge.setEditable(editable, allowTasks);",
            arguments: [
                "editable": isEditable,
                "allowTasks": configuration.allowsTaskInteractionInReadMode,
            ]
        ) { result in
            if case .failure(let error) = result {
                self.report(error)
            }
        }
    }

    private func applyTheme() {
        guard isReady else { return }
        let payload = MarkdownEditorThemePayload(
            theme: configuration.theme,
            backgroundColor: configuration.backgroundColor,
            contentInsets: configuration.contentInsets,
            traits: traitCollection
        )
        executeJavaScript(
            "window.MarkdownBridge.setTheme(theme);",
            arguments: payload.javaScriptArguments
        ) { result in
            if case .failure(let error) = result {
                self.report(error)
            }
        }
    }

    private func finishEditing() {
        getMarkdown { result in
            switch result {
            case .success(let markdown):
                self.blur()
                self.onDone?(markdown)
                self.delegate?.markdownEditorDidTapDone(self)
            case .failure(let error):
                self.report(error)
            }
        }
    }

    private func updateFormattingBarVisibility(animated: Bool) {
        let shouldShow = configuration.showsFormattingBar && isEditable && hasWebFocus
        guard shouldShow != !formattingBar.isHidden else { return }

        let changes = {
            self.formattingBar.alpha = shouldShow ? 1 : 0
        }
        let completion: (Bool) -> Void = { _ in
            self.formattingBar.isHidden = !shouldShow
        }

        if shouldShow {
            formattingBar.isHidden = false
        }

        let duration = UIAccessibility.isReduceMotionEnabled || !animated ? 0 : 0.18
        if duration == 0 {
            changes()
            completion(true)
        } else {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseOut],
                animations: changes,
                completion: completion
            )
        }

        guard isReady else { return }
        executeJavaScript(
            "window.MarkdownBridge.setFormattingBarInset(inset);",
            arguments: ["inset": shouldShow ? 54 : 0],
            completion: nil
        )
    }

    private func executeJavaScript(
        _ body: String,
        arguments: [String: Any] = [:],
        completion: ((Result<Any, MarkdownEditorError>) -> Void)? = nil
    ) {
        webView.callAsyncJavaScript(
            body,
            arguments: arguments,
            in: nil,
            in: .page,
            completionHandler: { result in
            switch result {
            case .success(let value):
                completion?(.success(value))
            case .failure(let error):
                completion?(.failure(.javaScript(error.localizedDescription)))
            }
        })
    }

    private func report(_ error: MarkdownEditorError, showInView: Bool = false) {
        if showInView {
            loadingIndicator.stopAnimating()
            errorLabel.text = "无法加载 Markdown 编辑器。\n\(error.localizedDescription)"
            errorLabel.isHidden = false
            webView.isHidden = true
        }
        onError?(error)
        delegate?.markdownEditor(self, didFail: error)
    }
}

extension MarkdownEditorView: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == messageHandlerName,
              let payload = message.body as? [String: Any],
              let type = payload["type"] as? String else {
            report(.invalidBridgeMessage)
            return
        }

        switch type {
        case "ready":
            isReady = true
            loadingIndicator.stopAnimating()
            webView.isHidden = false
            configureReadyEditor()
            onReady?()
            delegate?.markdownEditorDidBecomeReady(self)

        case "change":
            guard let markdown = payload["markdown"] as? String else {
                report(.invalidBridgeMessage)
                return
            }
            self.markdown = markdown
            onMarkdownChange?(markdown)
            delegate?.markdownEditor(self, didChangeMarkdown: markdown)

        case "selection":
            guard let rawStyle = payload["style"] as? String,
                  let style = MarkdownBlockStyle(rawValue: rawStyle) else { return }
            selectedBlockStyle = style
            formattingBar.select(style)
            onSelectionChange?(style)
            delegate?.markdownEditor(self, didSelectBlockStyle: style)

        case "focus":
            hasWebFocus = true
            updateFormattingBarVisibility(animated: true)
            delegate?.markdownEditorDidBeginEditing(self)

        case "blur":
            hasWebFocus = false
            updateFormattingBarVisibility(animated: true)
            delegate?.markdownEditorDidEndEditing(self)

        case "requestEdit":
            onRequestEditing?()
            delegate?.markdownEditorDidRequestEditing(self)

        case "link":
            guard let value = payload["url"] as? String,
                  let url = URL(string: value) else { return }
            onLinkTap?(url)
            delegate?.markdownEditor(self, didTapLink: url)

        case "height":
            guard let number = payload["value"] as? NSNumber else { return }
            let height = CGFloat(number.doubleValue)
            guard abs(height - contentHeight) > 0.5 else { return }
            contentHeight = height
            invalidateIntrinsicContentSize()
            onContentHeightChange?(height)

        case "error":
            let message = payload["message"] as? String ?? "未知错误"
            report(.javaScript(message), showInView: !isReady)

        default:
            report(.invalidBridgeMessage)
        }
    }
}

extension MarkdownEditorView: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        onLinkTap?(url)
        delegate?.markdownEditor(self, didTapLink: url)
        decisionHandler(.cancel)
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        report(.javaScript(error.localizedDescription), showInView: true)
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        report(.javaScript(error.localizedDescription), showInView: true)
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        pendingMarkdown = markdown
        loadEditorPage()
    }
}

extension MarkdownEditorView: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            onLinkTap?(url)
            delegate?.markdownEditor(self, didTapLink: url)
        }
        return nil
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

internal enum MarkdownEditorResources {
    static var editorHTMLURL: URL? {
        Bundle.module.url(
            forResource: "editor",
            withExtension: "html",
            subdirectory: "Vditor"
        )
    }
}
