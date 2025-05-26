//
//  Created by ktiays on 2025/1/20.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import CoreText
import Litext
import MarkdownParser
import UIKit

extension NSAttributedString.Key {
    static let contextView: NSAttributedString.Key = .init("contextView")
}

public final class MarkdownTextView: UIView {
    public enum LinkPayload {
        case url(URL)
        case string(String)
    }

    private let viewProvider: DrawingViewProvider
    public var nodes: [MarkdownBlockNode] = [] {
        didSet {
            updateText()
            setNeedsLayout()
        }
    }

    public var linkHandler: ((LinkPayload, NSRange, CGPoint) -> Void)?
    public var codePreviewHandler: ((String?, NSAttributedString) -> Void)?

    private var attributedText: NSAttributedString? {
        get { textView.attributedText }
        set { textView.attributedText = newValue ?? .init() }
    }

    private lazy var textView: LTXLabel = .init()
    public var theme: MarkdownTheme = .default

    private var drawingViewsDirtyMarks: [UIView: Bool] = [:]
    private var isDrawingViewsReady: Bool = false
    private var drawingToken: UUID = .init()

    deinit {
        releaseDrawingViews()
    }

    public convenience init() {
        self.init(viewProvider: DrawingViewProvider())
    }

    public init(viewProvider: DrawingViewProvider) {
        self.viewProvider = viewProvider
        super.init(frame: .zero)
        configureSubviews()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        textView.isSelectable = true
        textView.preferredMaxLayoutWidth = bounds.width
        textView.frame = bounds
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if isDrawingViewsReady {
            // Removes unused drawing views from the superview.
            var needsRemove: Set<UIView> = .init()
            for (drawingView, isDirty) in drawingViewsDirtyMarks {
                if isDirty, drawingView.superview == self {
                    needsRemove.insert(drawingView)
                }
            }
            for view in needsRemove {
                view.removeFromSuperview()
                drawingViewsDirtyMarks.removeValue(forKey: view)
            }
        }
    }

    public func boundingSize(for width: CGFloat) -> CGSize {
        textView.preferredMaxLayoutWidth = width
        return textView.intrinsicContentSize
    }

    private func releaseDrawingViews() {
        for view in drawingViewsDirtyMarks.keys {
            if let codeView = view as? CodeView {
                viewProvider.releaseCodeView(codeView)
            }
            if let tableView = view as? TableView {
                viewProvider.releaseTableView(tableView)
            }
        }
    }

    private func updateText() {
        // due to a bug in model gemini-flash, there might be a large of unknown empty whitespace inside the table
        // thus we hereby call the autoreleasepool to avoid large memory consumption
        autoreleasepool { self.updateTextExecute() }
    }

    private func updateTextExecute() {
        releaseDrawingViews()
        // Marks all drawing views as dirty.
        for view in drawingViewsDirtyMarks.keys {
            drawingViewsDirtyMarks[view] = true
        }

        func lineBoundingBox(_ line: CTLine, lineOrigin: CGPoint) -> CGRect {
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
            return .init(x: lineOrigin.x, y: lineOrigin.y - descent, width: width, height: ascent + descent)
        }

        let newDrawingToken = UUID()
        drawingToken = newDrawingToken

        let renderText = TextBuilder(nodes: nodes, viewProvider: viewProvider)
            .withTheme(theme)
            .withBulletDrawing { [weak self] context, line, lineOrigin, depth in
                guard let self, drawingToken == newDrawingToken else { return }
                let radius: CGFloat = 3
                let boundingBox = lineBoundingBox(line, lineOrigin: lineOrigin)

                context.setStrokeColor(theme.colors.body.cgColor)
                context.setFillColor(theme.colors.body.cgColor)
                let rect = CGRect(
                    x: boundingBox.minX - 16,
                    y: boundingBox.midY - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                if depth == 0 {
                    context.fillEllipse(in: rect)
                } else if depth == 1 {
                    context.strokeEllipse(in: rect)
                } else {
                    context.fill(rect)
                }
            }
            .withNumberedDrawing { [weak self] context, line, lineOrigin, index in
                guard let self, drawingToken == newDrawingToken else { return }
                let string = NSAttributedString(
                    string: "\(index).",
                    attributes: [
                        .font: theme.fonts.body,
                        .foregroundColor: theme.colors.body,
                    ]
                )
                let rect = lineBoundingBox(line, lineOrigin: lineOrigin).offsetBy(dx: -20, dy: 0)
                let path = CGPath(rect: rect, transform: nil)
                let framesetter = CTFramesetterCreateWithAttributedString(string)
                let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, string.length), path, nil)
                CTFrameDraw(frame, context)
            }
            .withCheckboxDrawing { [weak self] context, line, lineOrigin, isChecked in
                guard let self, drawingToken == newDrawingToken else { return }
                let rect = lineBoundingBox(line, lineOrigin: lineOrigin).offsetBy(dx: -20, dy: 0)
                let imageConfiguration = UIImage.SymbolConfiguration(scale: .small)
                let image = if isChecked {
                    UIImage(systemName: "checkmark.square.fill", withConfiguration: imageConfiguration)
                } else {
                    UIImage(systemName: "square", withConfiguration: imageConfiguration)
                }
                guard let image, let cgImage = image.cgImage else {
                    assertionFailure("Failed to load symbol image")
                    return
                }
                let imageSize = image.size
                let targetRect: CGRect = .init(
                    x: rect.minX,
                    y: rect.midY - imageSize.height / 2,
                    width: imageSize.width,
                    height: imageSize.height
                )
                context.clip(to: targetRect, mask: cgImage)
                context.setFillColor(theme.colors.body.withAlphaComponent(0.24).cgColor)
                context.fill(targetRect)
            }
            .withThematicBreakDrawing { [weak self] context, line, lineOrigin in
                guard let self, drawingToken == newDrawingToken else { return }
                let boundingBox = lineBoundingBox(line, lineOrigin: lineOrigin)

                context.setLineWidth(1)
                context.setStrokeColor(UIColor.label.withAlphaComponent(0.1).cgColor)
                context.move(to: .init(x: boundingBox.minX, y: boundingBox.midY))
                context.addLine(to: .init(x: boundingBox.minX + bounds.width, y: boundingBox.midY))
                context.strokePath()
            }
            .withCodeDrawing { [weak self] _, line, lineOrigin in
                guard let self, drawingToken == newDrawingToken else { return }
                guard let firstRun = line.glyphRuns().first else {
                    assertionFailure()
                    return
                }
                let attributes = firstRun.attributes
                guard let codeView = attributes[.contextView] as? CodeView else {
                    assertionFailure()
                    return
                }

                drawingViewsDirtyMarks[codeView] = false
                if codeView.superview != self {
                    addSubview(codeView)
                }
                let intrinsicContentSize = codeView.intrinsicContentSize
                let lineBoundingBox = lineBoundingBox(line, lineOrigin: lineOrigin)
                codeView.frame = .init(
                    origin: .init(x: lineOrigin.x, y: bounds.height - lineBoundingBox.maxY),
                    size: .init(width: bounds.width, height: intrinsicContentSize.height)
                )
                codeView.previewAction = { [weak self] in
                    guard let self else { return }
                    codePreviewHandler?($0, $1)
                }

                isDrawingViewsReady = true
            }
            .withTableDrawing { [weak self] _, line, lineOrigin in
                guard let self, drawingToken == newDrawingToken else { return }
                guard let firstRun = line.glyphRuns().first else {
                    assertionFailure()
                    return
                }
                let attributes = firstRun.attributes
                guard let tableView = attributes[.contextView] as? TableView else {
                    assertionFailure()
                    return
                }

                drawingViewsDirtyMarks[tableView] = false
                if tableView.superview != self {
                    addSubview(tableView)
                }
                let lineBoundingBox = lineBoundingBox(line, lineOrigin: lineOrigin)
                let intrinsicContentSize = tableView.intrinsicContentSize
                tableView.frame = .init(
                    x: lineOrigin.x,
                    y: bounds.height - lineBoundingBox.maxY,
                    width: bounds.width,
                    height: intrinsicContentSize.height
                )

                isDrawingViewsReady = true
            }
            .build()
        attributedText = renderText
    }

    private func configureSubviews() {
        updateText()
        textView.backgroundColor = .clear
        textView.attributedText = attributedText ?? .init()
        textView.tapHandler = { [weak self] highlightRegion, touchLocation in
            guard let self else { return }
            guard let highlightRegion else {
                return
            }
            let link = highlightRegion.attributes[NSAttributedString.Key.link]
            let range = highlightRegion.stringRange
            if let url = link as? URL {
                linkHandler?(.url(url), range, touchLocation)
            } else if let string = link as? String {
                linkHandler?(.string(string), range, touchLocation)
            }
        }
        if textView.superview != self {
            addSubview(textView)
        }
    }
}
