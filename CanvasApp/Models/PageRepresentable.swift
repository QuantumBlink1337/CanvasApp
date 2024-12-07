//
//  PageRepresentable.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/6/24.
//

import Foundation


protocol PageRepresentable : ItemRepresentable {
    var body: String {get}
    var attributedText: NSAttributedString? {get}
}
