//
//  PageView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/30/24.
//

import SwiftUI
import UIKit




struct PageView: View {
    var attributedContent: NSAttributedString
    
    var body: some View {
        HTMLTextView(attributedContent: attributedContent)
    }
}

