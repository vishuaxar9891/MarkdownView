//
//  MarkdownParser.swift
//  FlowMarkdownView
//
//  Created by 秋星桥 on 2025/1/2.
//

import cmark_gfm
import cmark_gfm_extensions
import Foundation

public class MarkdownParser {
    private var parser: UnsafeMutablePointer<cmark_parser>!

    public init() {
        let parser = cmark_parser_new(CMARK_OPT_DEFAULT)!
        self.parser = parser
        cmark_gfm_core_extensions_ensure_registered()
        let extensionNames = [
            "autolink",
            "strikethrough",
            "tagfilter",
            "tasklist",
            "table",
        ]
        for extensionName in extensionNames {
            guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
                assertionFailure()
                continue
            }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }
    }

    deinit {
        cmark_parser_free(parser)
        parser = nil
    }

    public func feed(_ text: String) -> [MarkdownBlockNode] {
        cmark_parser_feed(parser, text, text.utf8.count)
        let forked = cmark_parser_fork(parser)
        defer { cmark_parser_free(forked) }
        let node = cmark_parser_finish(forked)
        return dumpBlocks(root: node)
    }

    public func finalize() -> [MarkdownBlockNode] {
        let node = cmark_parser_finish(parser)
        return dumpBlocks(root: node)
    }

    public func reset() {
        cmark_parser_finish(parser)
    }
}
