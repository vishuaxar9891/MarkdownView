//
//  Created by ktiays on 2025/1/22.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import Foundation
import Splash
import UIKit

final class CodeHighlighter {
    private let queue: DispatchQueue
    private var taskVersion: Int64 = 0
    private var syntaxFormat: AttributedStringOutputFormat?

    init() {
        queue = DispatchQueue.global(qos: .background)
    }

    func updateTheme(_ theme: MarkdownTheme) {
        let codeTheme = theme.codeTheme(withFont: theme.fonts.code)
        syntaxFormat = AttributedStringOutputFormat(theme: codeTheme)
    }

    func highlight(
        code: String,
        language: String,
        delays: TimeInterval = 0,
        completion: @escaping ([NSRange: UIColor]) -> Void
    ) {
        taskVersion += 1
        let currentTaskVersion = taskVersion

        queue.async { [weak self] in
            guard let format = self?.syntaxFormat else { return }

            if delays > 0 {
                Thread.sleep(forTimeInterval: delays)
                if currentTaskVersion != self?.taskVersion {
                    return
                }
            }

            let result = self?.performHighlight(code: code, language: language, format: format)
            guard let result else { return }

            let attributes = self?.extractColorAttributes(from: result)
            guard let attributes else { return }

            if currentTaskVersion != self?.taskVersion {
                return
            }

            DispatchQueue.main.async {
                completion(attributes)
            }
        }
    }

    private func performHighlight(
        code: String,
        language: String,
        format: AttributedStringOutputFormat
    ) -> NSMutableAttributedString? {
        switch language.lowercased() {
        case "plaintext":
            return NSMutableAttributedString(string: code)
        case "swift":
            let splash = SyntaxHighlighter(format: format, grammar: SwiftGrammar())
            return splash.highlight(code).mutableCopy() as? NSMutableAttributedString
        default:
            let splash = SyntaxHighlighter(format: format)
            return splash.highlight(code).mutableCopy() as? NSMutableAttributedString
        }
    }

    private func extractColorAttributes(from attributedString: NSMutableAttributedString) -> [NSRange: UIColor] {
        var attributes: [NSRange: UIColor] = [:]
        let nsString = attributedString.string as NSString

        attributedString.enumerateAttribute(
            .foregroundColor,
            in: NSRange(location: 0, length: attributedString.length)
        ) { value, range, _ in
            if range.length == 1 {
                if let char = nsString.substring(with: range).first, char.isWhitespace {
                    return
                }
            }

            guard let color = value as? UIColor else { return }
            attributes[range] = color
        }

        return attributes
    }
}
