//
//  MarkdownParser+ReorderContext.swift
//  MarkdownView
//
//  Created by 秋星桥 on 5/27/25.
//

import cmark_gfm
import cmark_gfm_extensions
import Foundation

extension MarkdownParser {
    class ReorderContext {
        private var context: [MarkdownBlockNode] = []

        init() {}

        func append(_ node: MarkdownBlockNode) {
            processNode(node)
        }

        func complete() -> [MarkdownBlockNode] {
            defer { context.removeAll() }
            return context
        }
    }
}

private extension MarkdownParser.ReorderContext {
    func rawListItemByCherryPick(
        _ rawListItem: RawListItem
    ) -> (RawListItem, [MarkdownBlockNode]) {
        let children = rawListItem.children
        var newChildren: [MarkdownBlockNode] = []
        var pickedNodes: [MarkdownBlockNode] = []

        for child in children {
            switch child {
            case .codeBlock, .table, .heading, .thematicBreak:
                pickedNodes.append(child)
            case let .bulletedList(isTight, items):
                var resultItems: [RawListItem] = []
                for item in items {
                    let (newItem, picked) = rawListItemByCherryPick(item)
                    resultItems.append(newItem)
                    pickedNodes.append(contentsOf: picked)
                }
                newChildren.append(.bulletedList(isTight: isTight, items: resultItems))
            case let .numberedList(isTight, start, items):
                var resultItems: [RawListItem] = []
                for item in items {
                    let (newItem, picked) = rawListItemByCherryPick(item)
                    resultItems.append(newItem)
                    pickedNodes.append(contentsOf: picked)
                }
                newChildren.append(.numberedList(isTight: isTight, start: start, items: resultItems))
            case let .taskList(isTight, items):
                var resultItems: [RawTaskListItem] = []
                for item in items {
                    let (newItem, picked) = rawTaskListItemByCherryPick(item)
                    resultItems.append(newItem)
                    pickedNodes.append(contentsOf: picked)
                }
                newChildren.append(.taskList(isTight: isTight, items: resultItems))
            default:
                newChildren.append(child)
            }
        }

        return (RawListItem(children: newChildren), pickedNodes)
    }

    func rawTaskListItemByCherryPick(
        _ rawTaskListItem: RawTaskListItem
    ) -> (RawTaskListItem, [MarkdownBlockNode]) {
        let children = rawTaskListItem.children
        var newChildren: [MarkdownBlockNode] = []
        var pickedNodes: [MarkdownBlockNode] = []

        for child in children {
            switch child {
            case .codeBlock, .table, .heading, .thematicBreak:
                pickedNodes.append(child)
            case let .bulletedList(isTight, items):
                var resultItems: [RawListItem] = []
                for item in items {
                    let (newItem, picked) = rawListItemByCherryPick(item)
                    resultItems.append(newItem)
                    pickedNodes.append(contentsOf: picked)
                }
                newChildren.append(.bulletedList(isTight: isTight, items: resultItems))
            case let .numberedList(isTight, start, items):
                var resultItems: [RawListItem] = []
                for item in items {
                    let (newItem, picked) = rawListItemByCherryPick(item)
                    resultItems.append(newItem)
                    pickedNodes.append(contentsOf: picked)
                }
                newChildren.append(.numberedList(isTight: isTight, start: start, items: resultItems))
            case let .taskList(isTight, items):
                var resultItems: [RawTaskListItem] = []
                for item in items {
                    let (newItem, picked) = rawTaskListItemByCherryPick(item)
                    resultItems.append(newItem)
                    pickedNodes.append(contentsOf: picked)
                }
                newChildren.append(.taskList(isTight: isTight, items: resultItems))
            default:
                newChildren.append(child)
            }
        }

        return (RawTaskListItem(isCompleted: rawTaskListItem.isCompleted, children: newChildren), pickedNodes)
    }

    func processNodeInsideListEnvironment(
        _ node: MarkdownBlockNode
    ) -> [MarkdownBlockNode] {
        switch node {
        case let .bulletedList(isTight, items):
            return processListItems(items: items) { processedItems in
                .bulletedList(isTight: isTight, items: processedItems)
            }
        case let .numberedList(isTight, start, items):
            var containsElementsToExtract = false
            for item in items {
                let (_, pickedNodes) = rawListItemByCherryPick(item)
                if !pickedNodes.isEmpty {
                    containsElementsToExtract = true
                    break
                }
            }
            if containsElementsToExtract {
                return processListItems(items: items) { processedItems in
                    .bulletedList(isTight: isTight, items: processedItems)
                }
            } else {
                return processListItems(items: items) { processedItems in
                    .numberedList(isTight: isTight, start: start, items: processedItems)
                }
            }
        case let .taskList(isTight, items):
            return processTaskListItems(items: items) { processedItems in
                .taskList(isTight: isTight, items: processedItems)
            }
        default:
            assertionFailure("unsupported node type in list environment")
            return []
        }
    }

    private func processListItems(
        items: [RawListItem],
        createList: ([RawListItem]) -> MarkdownBlockNode
    ) -> [MarkdownBlockNode] {
        var result: [MarkdownBlockNode] = []
        var currentItems: [RawListItem] = []

        for itemIndex in 0 ..< items.count {
            let item = items[itemIndex]
            let (processedItem, pickedNodes) = rawListItemByCherryPick(item)
            currentItems.append(processedItem)
            if !pickedNodes.isEmpty {
                if !currentItems.isEmpty {
                    result.append(createList(currentItems))
                    currentItems = []
                }
                result.append(contentsOf: pickedNodes)
            } else if itemIndex == items.count - 1, !currentItems.isEmpty {
                result.append(createList(currentItems))
            }
        }
        return result
    }

    private func processTaskListItems(
        items: [RawTaskListItem],
        createList: ([RawTaskListItem]) -> MarkdownBlockNode
    ) -> [MarkdownBlockNode] {
        var result: [MarkdownBlockNode] = []
        var currentItems: [RawTaskListItem] = []

        for itemIndex in 0 ..< items.count {
            let item = items[itemIndex]
            let (processedItem, pickedNodes) = rawTaskListItemByCherryPick(item)
            currentItems.append(processedItem)
            if !pickedNodes.isEmpty {
                if !currentItems.isEmpty {
                    result.append(createList(currentItems))
                    currentItems = []
                }
                result.append(contentsOf: pickedNodes)
            } else if itemIndex == items.count - 1, !currentItems.isEmpty {
                result.append(createList(currentItems))
            }
        }
        return result
    }

    func processNode(_ node: MarkdownBlockNode) {
        switch node {
        case let .blockquote(children):
            context.append(.blockquote(children: children))
        case .bulletedList:
            let nodes = processNodeInsideListEnvironment(node)
            context.append(contentsOf: nodes)
        case .numberedList:
            let nodes = processNodeInsideListEnvironment(node)
            context.append(contentsOf: nodes)
        case .taskList:
            let nodes = processNodeInsideListEnvironment(node)
            context.append(contentsOf: nodes)
        case let .codeBlock(fenceInfo, content):
            context.append(.codeBlock(fenceInfo: fenceInfo, content: content))
        case let .paragraph(content):
            context.append(.paragraph(content: content))
        case let .heading(level, content):
            context.append(.heading(level: level, content: content))
        case let .table(columnAlignments, rows):
            context.append(.table(columnAlignments: columnAlignments, rows: rows))
        case .thematicBreak:
            context.append(.thematicBreak)
        }
    }
}
