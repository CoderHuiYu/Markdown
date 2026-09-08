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

    private var markdown = ""

    private lazy var markdownView: MarkdownView = {
        let markdownView = MarkdownView(
            css: MarkdownReaderStyle.make(traits: self.traitCollection),
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
            css: MarkdownReaderStyle.make(traits: traitCollection),
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

}
