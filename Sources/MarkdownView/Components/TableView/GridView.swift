//
//  GridView.swift
//  MarkdownView
//
//  Created by ktiays on 2025/1/27.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import UIKit

final class GridView: UIView {
    private var widths: [CGFloat] = []
    private var heights: [CGFloat] = []
    private var totalWidth: CGFloat = 0
    private var totalHeight: CGFloat = 0

    private lazy var shapeLayer: CAShapeLayer = .init()
    var padding: CGFloat = 2

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    @MainActor
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        shapeLayer.lineWidth = 1
        shapeLayer.strokeColor = UIColor.label.cgColor
        layer.addSublayer(shapeLayer)

        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        shapeLayer.strokeColor = UIColor.label.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        drawGrid()
    }

    private func drawGrid() {
        let path = UIBezierPath()

        // Draw vertical lines
        var x: CGFloat = padding
        path.move(to: .init(x: x, y: padding))
        path.addLine(to: .init(x: x, y: totalHeight + padding))

        for width in widths {
            x += width
            path.move(to: .init(x: x, y: padding))
            path.addLine(to: .init(x: x, y: totalHeight + padding))
        }

        // Draw horizontal lines
        var y: CGFloat = padding
        path.move(to: .init(x: padding, y: y))
        path.addLine(to: .init(x: totalWidth + padding, y: y))

        for height in heights {
            y += height
            path.move(to: .init(x: padding, y: y))
            path.addLine(to: .init(x: totalWidth + padding, y: y))
        }

        shapeLayer.path = path.cgPath
    }

    func update(widths: [CGFloat], heights: [CGFloat]) {
        self.widths = widths
        self.heights = heights
        totalWidth = widths.reduce(0, +)
        totalHeight = heights.reduce(0, +)
        setNeedsLayout()
    }
}
