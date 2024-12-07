//
//  ViewUtilities.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/29/24.
//

import Foundation
import SwiftUI


func HexToColor(_ hex: String) -> SwiftUI.Color? {
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexString = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
    
    guard let intVal = Int(hexString, radix: 16) else { return nil }
    
    let red = Double((intVal >> 16) & 0xFF) / 255.0
    let green = Double((intVal >> 8) & 0xFF) / 255.0
    let blue = Double(intVal & 0xFF) / 255.0
    
    return SwiftUI.Color(red: red, green: green, blue: blue)
}
func colorToHex(_ color: SwiftUI.Color) -> String? {
    // Convert to UIColor to extract RGBA components
    guard let components = UIColor(color).cgColor.components else {
        return nil
    }
    
    // Handle grayscale colors
    let red = components[0]
    let green = components.count > 1 ? components[1] : components[0]
    let blue = components.count > 2 ? components[2] : components[0]
    
    // Format the color values to hexadecimal (ignoring alpha)
    let redHex = String(format: "%02X", Int(red * 255))
    let greenHex = String(format: "%02X", Int(green * 255))
    let blueHex = String(format: "%02X", Int(blue * 255))
    
    return "#\(redHex)\(greenHex)\(blueHex)"
}


struct HTMLTextView: UIViewRepresentable {
    func updateUIView(_ uiView: UITextView, context: Context) {
        
    }
    
    var htmlContent: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false  // Disable editing
        textView.isScrollEnabled = true  // Enable scrolling for long content
        textView.dataDetectorTypes = .all // Automatically detect links, phone numbers, etc.
        
        // Apply the HTML content
        if let data = htmlContent.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                textView.attributedText = attributedString
            }
        }
        
        return textView
    }
}
