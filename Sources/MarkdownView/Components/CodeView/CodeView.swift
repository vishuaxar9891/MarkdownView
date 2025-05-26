//
//  Created by ktiays on 2025/1/22.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import Litext
import UIKit

final class CodeView: UIView {
    var theme: MarkdownTheme = .default {
        didSet {
            languageLabel.font = theme.fonts.code
            highlighter.updateTheme(theme)
        }
    }

    var language: String = "" {
        didSet {
            languageLabel.text = language
        }
    }

    var previewAction: ((String?, NSAttributedString) -> Void)?

    private var _content: String?
    var content: String? {
        set {
            if _content != newValue {
                let oldValue = _content
                _content = newValue
                let delays = shouldDelayHighlight(oldValue: oldValue, newValue: newValue)
                if delays == 0 { calculatedAttributes.removeAll() }
                updateHighlightedContent()
                performHighlight(with: newValue, delays: delays)
            }
        }
        get { _content }
    }

    private var calculatedAttributes: [NSRange: UIColor] = [:]
    private let highlighter = CodeHighlighter()

    lazy var barView: UIView = .init()
    lazy var scrollView: UIScrollView = .init()
    lazy var languageLabel: UILabel = .init()
    lazy var textView: LTXLabel = .init()
    lazy var copyButton: UIButton = .init()
    lazy var previewButton: UIButton = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func intrinsicHeight(for content: String, theme: MarkdownTheme = .default) -> CGFloat {
        CodeViewConfiguration.intrinsicHeight(for: content, theme: theme)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        performLayout()
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = languageLabel.intrinsicContentSize
        let barHeight = labelSize.height + CodeViewConfiguration.barPadding * 2
        let textSize = textView.intrinsicContentSize
        let supposedHeight = Self.intrinsicHeight(for: content ?? "", theme: theme)

        return CGSize(
            width: max(
                labelSize.width + CodeViewConfiguration.barPadding * 2,
                textSize.width + CodeViewConfiguration.codePadding * 2
            ),
            height: max(
                barHeight + textSize.height + CodeViewConfiguration.codePadding * 2,
                supposedHeight
            )
        )
    }

    @objc func handleCopy(_: UIButton) {
        UIPasteboard.general.string = content
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @objc func handlePreview(_: UIButton) {
        previewAction?(language, textView.attributedText)
    }

    // MARK: - Highlight Logic

    private func shouldDelayHighlight(oldValue: String?, newValue: String?) -> TimeInterval {
        if let oldValue, !oldValue.isEmpty, newValue?.contains(oldValue) == true {
            // Incremental modification, delay the highlight task.
            0.1
        } else {
            // Non-incremental modification
            0
        }
    }

    private func performHighlight(with code: String?, delays: TimeInterval) {
        guard let code else { return }

        highlighter.highlight(
            code: code,
            language: language,
            delays: delays
        ) { [weak self] attributes in
            if attributes.count > self?.calculatedAttributes.count ?? 0 {
                self?.calculatedAttributes = attributes
                self?.updateHighlightedContent()
            }
        }
    }

    private func updateHighlightedContent() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CodeViewConfiguration.codeLineSpacing

        guard let content = _content else {
            textView.attributedText = .init()
            return
        }

        let plainTextColor = theme.colors.code
        let attributedContent: NSMutableAttributedString = .init(
            string: content,
            attributes: [
                .font: theme.fonts.code,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: plainTextColor,
            ]
        )
        let length = attributedContent.length
        for attribute in calculatedAttributes {
            if attribute.key.upperBound >= length || attribute.value == plainTextColor {
                continue
            }
            let part = attributedContent.attributedSubstring(from: attribute.key).string
            if part.allSatisfy(\.isWhitespace) {
                continue
            }
            attributedContent.addAttributes([
                .foregroundColor: attribute.value,
            ], range: attribute.key)
        }
        textView.attributedText = attributedContent
    }
}

extension CodeView: LTXAttributeStringRepresentable {
    func attributedStringRepresentation() -> NSAttributedString {
        textView.attributedText
    }
}
