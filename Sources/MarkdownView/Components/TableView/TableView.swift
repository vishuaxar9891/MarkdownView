//
//  Created by ktiays on 2025/1/27.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import Litext
import UIKit

final class TableView: UIView {
    typealias Rows = [NSAttributedString]

    // MARK: - Constants

    private let tableViewPadding: CGFloat = 2
    private let cellPadding: CGFloat = 10
    private let maximumCellWidth: CGFloat = 200

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = .init()
    private lazy var gridView: GridView = .init()

    // MARK: - Properties

    var contents: [Rows] = [] {
        didSet {
            configureCells()
            setNeedsLayout()
        }
    }

    private var cellManager = TableViewCellManager()
    private var widths: [CGFloat] = []
    private var heights: [CGFloat] = []

    // MARK: - Computed Properties

    private var numberOfRows: Int {
        contents.count
    }

    private var numberOfColumns: Int {
        contents.first?.count ?? 0
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func configureSubviews() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.addSubview(gridView)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.clipsToBounds = false
        scrollView.frame = bounds
        scrollView.contentSize = intrinsicContentSize
        gridView.frame = bounds

        layoutCells()
    }

    private func layoutCells() {
        guard !cellManager.cellSizes.isEmpty, !cellManager.cells.isEmpty else {
            return
        }

        var x: CGFloat = 0
        var y: CGFloat = 0

        for row in 0 ..< numberOfRows {
            for column in 0 ..< numberOfColumns {
                let index = row * numberOfColumns + column
                let cellSize = cellManager.cellSizes[index]
                let cell = cellManager.cells[index]
                let idealCellSize = cell.intrinsicContentSize

                cell.frame = .init(
                    x: x + cellPadding + tableViewPadding,
                    y: y + (cellSize.height - idealCellSize.height) / 2 + tableViewPadding,
                    width: ceil(idealCellSize.width),
                    height: ceil(idealCellSize.height)
                )

                let columnWidth = widths[column]
                x += columnWidth
            }
            x = 0
            y += heights[row]
        }
    }

    // MARK: - Content Size

    var intrinsicContentHeight: CGFloat {
        ceil(heights.reduce(0, +)) + tableViewPadding * 2
    }

    override var intrinsicContentSize: CGSize {
        .init(
            width: ceil(widths.reduce(0, +)) + tableViewPadding * 2,
            height: intrinsicContentHeight
        )
    }

    // MARK: - Cell Configuration

    private func configureCells() {
        cellManager.configureCells(
            for: contents,
            in: scrollView,
            cellPadding: cellPadding,
            maximumCellWidth: maximumCellWidth
        )

        widths = cellManager.widths
        heights = cellManager.heights

        gridView.padding = tableViewPadding
        gridView.update(widths: widths, heights: heights)
    }
}
