//
//  MathView.swift
//  MarkdownView
//
//  Created by 秋星桥 on 5/27/25.
//

import Litext
import SwiftMath
import UIKit

class MathView: UIImageView, LTXAttributeStringRepresentable {
    let text: String
    init(text: String, image: UIImage, theme: MarkdownTheme) {
        self.text = text
        super.init(frame: .init(
            x: 0,
            y: 0,
            width: image.size.width,
            height: image.size.height
        ))
        self.image = image.withRenderingMode(.alwaysTemplate)
        tintColor = theme.colors.body
        contentMode = .scaleAspectFit
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func attributedStringRepresentation() -> NSAttributedString {
        // copy as image
        .init(string: "$\(text)$")
    }
}
