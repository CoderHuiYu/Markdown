import MarkdownEditor
import UIKit

final class ViewController: UIViewController {
    private enum Document {
        static let resourceName = "7月29日 云同步功能逻辑与AI联动规则"
        static let fileExtension = "md"
    }

    private enum DocumentLoadingError: LocalizedError {
        case resourceNotFound
        case emptyDocument

        var errorDescription: String? {
            switch self {
            case .resourceNotFound:
                return "示例 Markdown 文件未加入 Demo Target。"
            case .emptyDocument:
                return "示例 Markdown 文件内容为空。"
            }
        }
    }

    private lazy var editorView: MarkdownEditorView = {
        var configuration = MarkdownEditorConfiguration()
        configuration.isEditable = false
        configuration.showsFormattingBar = true
        configuration.allowsTaskInteractionInReadMode = true

        let editor = MarkdownEditorView(configuration: configuration)
        editor.delegate = self
        return editor
    }()

    private lazy var editButton = UIBarButtonItem(
        title: "编辑",
        style: .plain,
        target: self,
        action: #selector(toggleEditing)
    )

    private var documentMarkdown = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        loadDocument()
    }

    private func configureView() {
        title = "会议纪要"
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = editButton

        view.addSubview(editorView)
        editorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadDocument() {
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

            documentMarkdown = markdown
            editorView.setMarkdown(markdown)
        } catch {
            show(error)
        }
    }

    @objc private func toggleEditing() {
        setEditingMode(!editorView.isEditable)
    }

    private func setEditingMode(_ isEditing: Bool) {
        editorView.isEditable = isEditing
        editButton.title = isEditing ? "阅读" : "编辑"
        editButton.accessibilityLabel = isEditing ? "切换到阅读模式" : "编辑笔记"

        if isEditing {
            editorView.focus()
        } else {
            editorView.blur()
            editorView.getMarkdown { [weak self] result in
                if case .success(let markdown) = result {
                    self?.documentMarkdown = markdown
                }
            }
        }
    }

    private func show(_ error: Error) {
        let alert = UIAlertController(
            title: "无法加载示例",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: MarkdownEditorViewDelegate {
    func markdownEditorDidRequestEditing(_ editor: MarkdownEditorView) {
        setEditingMode(true)
    }

    func markdownEditor(_ editor: MarkdownEditorView, didChangeMarkdown markdown: String) {
        documentMarkdown = markdown
    }

    func markdownEditor(_ editor: MarkdownEditorView, didTapLink url: URL) {
        UIApplication.shared.open(url)
    }

    func markdownEditorDidTapDone(_ editor: MarkdownEditorView) {
        documentMarkdown = editor.markdown
        setEditingMode(false)
    }

    func markdownEditor(_ editor: MarkdownEditorView, didFail error: MarkdownEditorError) {
        // The reusable view owns its loading-error presentation. Keep the Demo
        // alive so hosts can also observe and log recoverable runtime warnings.
        print("MarkdownEditor: \(error.localizedDescription)")
    }
}
