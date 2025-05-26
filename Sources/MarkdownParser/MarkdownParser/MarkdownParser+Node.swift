//
//  MarkdownParser+Node.swift
//  FlowMarkdownView
//
//  Created by 秋星桥 on 2025/1/3.
//

import cmark_gfm
import cmark_gfm_extensions
import Foundation

extension MarkdownParser {
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
            // 处理项目列表，保持列表项与提取内容的正确顺序
            return processListItems(items: items) { processedItems in
                .bulletedList(isTight: isTight, items: processedItems)
            }

        case let .numberedList(isTight, start, items):
            // 检查是否包含需要提取的元素
            var containsElementsToExtract = false
            for item in items {
                let (_, pickedNodes) = rawListItemByCherryPick(item)
                if !pickedNodes.isEmpty {
                    containsElementsToExtract = true
                    break
                }
            }

            // 如果包含需要提取的元素，则转换为 bulletedList 避免编号不一致问题
            if containsElementsToExtract {
                return processListItems(items: items) { processedItems in
                    .bulletedList(isTight: isTight, items: processedItems)
                }
            } else {
                // 不包含需要提取的元素，保持原样
                return processListItems(items: items) { processedItems in
                    .numberedList(isTight: isTight, start: start, items: processedItems)
                }
            }

        case let .taskList(isTight, items):
            // 处理任务列表，处理逻辑类似
            return processTaskListItems(items: items) { processedItems in
                .taskList(isTight: isTight, items: processedItems)
            }

        // 其他 case 保持不变
        default:
            assertionFailure("unsupported node type in list environment")
            return []
        }
    }

    // 处理通用列表项的辅助方法
    private func processListItems(
        items: [RawListItem],
        createList: ([RawListItem]) -> MarkdownBlockNode
    ) -> [MarkdownBlockNode] {
        var result: [MarkdownBlockNode] = []
        var currentItems: [RawListItem] = []

        for itemIndex in 0 ..< items.count {
            let item = items[itemIndex]
            let (processedItem, pickedNodes) = rawListItemByCherryPick(item)

            // 添加当前处理后的列表项
            currentItems.append(processedItem)

            if !pickedNodes.isEmpty {
                // 如果有提取内容，创建一个包含当前项目的列表
                if !currentItems.isEmpty {
                    result.append(createList(currentItems))
                    currentItems = [] // 清空当前项目集合
                }

                // 添加提取的节点
                result.append(contentsOf: pickedNodes)
            } else if itemIndex == items.count - 1, !currentItems.isEmpty {
                // 如果是最后一项且没有提取内容，添加剩余项目
                result.append(createList(currentItems))
            }
        }

        return result
    }

    // 处理任务列表项的辅助方法
    private func processTaskListItems(
        items: [RawTaskListItem],
        createList: ([RawTaskListItem]) -> MarkdownBlockNode
    ) -> [MarkdownBlockNode] {
        var result: [MarkdownBlockNode] = []
        var currentItems: [RawTaskListItem] = []

        for itemIndex in 0 ..< items.count {
            let item = items[itemIndex]
            let (processedItem, pickedNodes) = rawTaskListItemByCherryPick(item)

            // 添加当前处理后的列表项
            currentItems.append(processedItem)

            if !pickedNodes.isEmpty {
                // 如果有提取内容，创建一个包含当前项目的列表
                if !currentItems.isEmpty {
                    result.append(createList(currentItems))
                    currentItems = [] // 清空当前项目集合
                }

                // 添加提取的节点
                result.append(contentsOf: pickedNodes)
            } else if itemIndex == items.count - 1, !currentItems.isEmpty {
                // 如果是最后一项且没有提取内容，添加剩余项目
                result.append(createList(currentItems))
            }
        }

        return result
    }

    func processNode(
        _ node: MarkdownBlockNode,
        context: inout [MarkdownBlockNode]
    ) {
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

    func dumpBlocks(root: UnsafeNode?) -> [MarkdownBlockNode] {
        guard let root else {
            assertionFailure()
            return []
        }
        assert(root.pointee.type == CMARK_NODE_DOCUMENT.rawValue)

        let nodeList = root.children.compactMap(MarkdownBlockNode.init(unsafeNode:))

        var processedNodes: [MarkdownBlockNode] = []
        for node in nodeList {
            processNode(node, context: &processedNodes)
        }
        return processedNodes
    }
}
