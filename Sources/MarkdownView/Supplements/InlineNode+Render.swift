//
//  InlineNode+Render.swift
//  MarkdownView
//
//  Created by 秋星桥 on 2025/1/3.
//

import Foundation
import Litext
import MarkdownParser
import SwiftMath
import UIKit

extension [MarkdownInlineNode] {
    func render(theme: MarkdownTheme) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        for node in self {
            result.append(node.render(theme: theme))
        }
        return result
    }
}

extension MarkdownInlineNode {
    func replaceMathContentInText(_ attributedString: NSMutableAttributedString, theme: MarkdownTheme) {
        let text = attributedString.string

        let originalAttributes = attributedString.length > 0 ?
            attributedString.attributes(at: 0, effectiveRange: nil) : [:]

        let parsedContent = MathRenderer.parseMathInText(text, textAttributes: originalAttributes)

        let hasMath = parsedContent.contains { $0.type == .math }
        guard hasMath else { return }

        attributedString.deleteCharacters(in: NSRange(location: 0, length: attributedString.length))
        for content in parsedContent {
            switch content.type {
            case .text:
                let textContent = content.content
                let textAttrString = NSAttributedString(string: textContent, attributes: content.attributes)
                attributedString.append(textAttrString)

            case .math:
                let mathContent = content.content
                let currentFont = (originalAttributes[.font] as? UIFont) ?? theme.fonts.body
                let currentColor = (originalAttributes[.foregroundColor] as? UIColor) ?? theme.colors.body

                if let mathImage = MathRenderer.renderToImage(
                    latex: mathContent,
                    fontSize: currentFont.pointSize,
                    textColor: currentColor
                ) {
                    let attachment: LTXAttachment = .init()
                    let mathView = MathView(text: mathContent, image: mathImage, theme: theme)
                    attachment.view = mathView
                    attachment.size = mathView.intrinsicContentSize

                    attributedString.append(
                        NSAttributedString(
                            string: LTXReplacementText,
                            attributes: [
                                LTXAttachmentAttributeName: attachment,
                                kCTRunDelegateAttributeName as NSAttributedString.Key: attachment.runDelegate,
                            ]
                        )
                    )
                } else {
                    let fallbackText = "$\(mathContent)$"
                    let fallbackString = NSAttributedString(
                        string: fallbackText,
                        attributes: [
                            .font: currentFont,
                            .foregroundColor: currentColor,
                            .backgroundColor: UIColor.red.withAlphaComponent(0.1),
                        ]
                    )
                    attributedString.append(fallbackString)
                }
            }
        }
    }

    func render(text: String, theme: MarkdownTheme) -> NSAttributedString {
        let text = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: theme.fonts.body,
                .foregroundColor: theme.colors.body,
            ]
        )
        replaceMathContentInText(text, theme: theme)
        return text
    }

    func render(theme: MarkdownTheme) -> NSAttributedString {
        switch self {
        case let .text(string):
            return render(text: string, theme: theme)
        case .softBreak:
            return NSAttributedString(string: " ", attributes: [
                .font: theme.fonts.body,
                .foregroundColor: theme.colors.body,
            ])
        case .lineBreak:
            return NSAttributedString(string: "\n", attributes: [
                .font: theme.fonts.body,
                .foregroundColor: theme.colors.body,
            ])
        case let .code(string):
            return NSAttributedString(
                string: "\(string)",
                attributes: [
                    .font: theme.fonts.codeInline,
                    .foregroundColor: theme.colors.code,
                    .backgroundColor: theme.colors.codeBackground.withAlphaComponent(0.05),
                ]
            )
        case let .html(content):
            return NSAttributedString(
                string: "\(content)",
                attributes: [
                    .font: theme.fonts.codeInline,
                    .foregroundColor: theme.colors.code,
                    .backgroundColor: theme.colors.codeBackground.withAlphaComponent(0.05),
                ]
            )
        case let .emphasis(children):
            let ans = NSMutableAttributedString()
            children.map { $0.render(theme: theme) }.forEach { ans.append($0) }
            ans.addAttributes(
                [
                    .underlineStyle: NSUnderlineStyle.thick.rawValue,
                    .underlineColor: theme.colors.emphasis,
                ],
                range: NSRange(location: 0, length: ans.length)
            )
            return ans
        case let .strong(children):
            let ans = NSMutableAttributedString()
            children.map { $0.render(theme: theme) }.forEach { ans.append($0) }
            ans.addAttributes(
                [.font: theme.fonts.bold],
                range: NSRange(location: 0, length: ans.length)
            )
            return ans
        case let .strikethrough(children):
            let ans = NSMutableAttributedString()
            children.map { $0.render(theme: theme) }.forEach { ans.append($0) }
            ans.addAttributes(
                [.strikethroughStyle: NSUnderlineStyle.thick.rawValue],
                range: NSRange(location: 0, length: ans.length)
            )
            return ans
        case let .link(destination, children):
            let ans = NSMutableAttributedString()
            children.map { $0.render(theme: theme) }.forEach { ans.append($0) }
            ans.addAttributes(
                [
                    .link: destination,
                    .foregroundColor: theme.colors.highlight,
                ],
                range: NSRange(location: 0, length: ans.length)
            )
            return ans
        case let .image(source, _): // children => alternative text can be ignored?
            return NSAttributedString(
                string: source,
                attributes: [
                    .link: source,
                    .font: theme.fonts.body,
                    .foregroundColor: theme.colors.body,
                ]
            )
        }
    }
}
