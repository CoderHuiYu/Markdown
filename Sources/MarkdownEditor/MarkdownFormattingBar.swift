import UIKit

/// The compact native formatting surface shown above the software keyboard.
public final class MarkdownFormattingBar: UIView {
    var onSelectBlockStyle: ((MarkdownBlockStyle) -> Void)?
    var onDone: (() -> Void)?

    public private(set) var selectedBlockStyle: MarkdownBlockStyle = .paragraph

    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let separator = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let doneButton = UIButton(type: .system)
    private var blockButtons: [MarkdownBlockStyle: UIButton] = [:]

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func select(_ style: MarkdownBlockStyle) {
        guard selectedBlockStyle != style else { return }
        selectedBlockStyle = style
        updateButtonStates()
    }

    private func configureView() {
        accessibilityIdentifier = "markdown-editor-formatting-bar"
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 12)

        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        separator.backgroundColor = .separator
        backgroundView.contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        scrollView.alwaysBounceHorizontal = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delaysContentTouches = false
        backgroundView.contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 0
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        configureDoneButton()
        backgroundView.contentView.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        let margin = backgroundView.contentView.layoutMarginsGuide
        backgroundView.contentView.directionalLayoutMargins = directionalLayoutMargins
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            separator.leadingAnchor.constraint(equalTo: backgroundView.contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: backgroundView.contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            scrollView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -6),
            scrollView.centerYAnchor.constraint(equalTo: margin.centerYAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 44),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            doneButton.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            doneButton.centerYAnchor.constraint(equalTo: margin.centerYAnchor),
            doneButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 54),
        ])

        addBlockButton(title: "H₁", accessibilityLabel: "一级标题", style: .heading1)
        addBlockButton(title: "H₂", accessibilityLabel: "二级标题", style: .heading2)
        addBlockButton(title: "H₃", accessibilityLabel: "三级标题", style: .heading3)
        addBlockButton(title: "H₄", accessibilityLabel: "四级标题", style: .heading4)
        addBlockButton(title: "T", accessibilityLabel: "正文", style: .paragraph)
        addBlockButton(
            systemImage: "list.bullet",
            accessibilityLabel: "项目符号列表",
            style: .unorderedList
        )
        addBlockButton(
            systemImage: "checkmark.square",
            accessibilityLabel: "任务列表",
            style: .taskList
        )

        updateButtonStates()
    }

    private func configureDoneButton() {
        doneButton.setTitle("完成", for: .normal)
        doneButton.setTitleColor(.label, for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        doneButton.titleLabel?.adjustsFontForContentSizeCategory = true
        doneButton.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 17, weight: .semibold)
        )
        doneButton.accessibilityLabel = "完成编辑"
        doneButton.accessibilityIdentifier = "markdown-editor-done"
        doneButton.addAction(UIAction { [weak self] _ in
            self?.onDone?()
        }, for: .touchUpInside)
        doneButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func addBlockButton(
        title: String,
        accessibilityLabel: String,
        style: MarkdownBlockStyle
    ) {
        let button = makeBlockButton(accessibilityLabel: accessibilityLabel, style: style)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: .systemFont(ofSize: 24, weight: .regular)
        )
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        install(button, for: style)
    }

    private func addBlockButton(
        systemImage: String,
        accessibilityLabel: String,
        style: MarkdownBlockStyle
    ) {
        let button = makeBlockButton(accessibilityLabel: accessibilityLabel, style: style)
        let symbol = UIImage.SymbolConfiguration(textStyle: .title2, scale: .medium)
        button.setImage(UIImage(systemName: systemImage, withConfiguration: symbol), for: .normal)
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        install(button, for: style)
    }

    private func makeBlockButton(
        accessibilityLabel: String,
        style: MarkdownBlockStyle
    ) -> UIButton {
        let button = UIButton(type: .custom)
        button.tintColor = .label
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.label, for: .selected)
        button.setTitleColor(.secondaryLabel, for: .highlighted)
        button.accessibilityLabel = accessibilityLabel
        button.accessibilityIdentifier = "markdown-editor-\(style.rawValue)"
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 12
        button.addAction(UIAction { [weak self] _ in
            self?.onSelectBlockStyle?(style)
        }, for: .touchUpInside)
        return button
    }

    private func install(_ button: UIButton, for style: MarkdownBlockStyle) {
        blockButtons[style] = button
        stackView.addArrangedSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func updateButtonStates() {
        for (style, button) in blockButtons {
            let isSelected = style == selectedBlockStyle
            button.isSelected = isSelected
            button.backgroundColor = isSelected ? .tertiarySystemFill : .clear
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }
}
