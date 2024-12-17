//
//  ViewUtilities.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/29/24.
//

import Foundation
import SwiftUI

import UIKit
import HTMLStreamer

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }

        // Ensure the string has exactly 6 characters (RRGGBB format)
        guard hexSanitized.count == 6, let hexValue = Int(hexSanitized, radix: 16) else {
            self.init(white: 1.0, alpha: 1.0) // Default color (white)
            return
        }
        
        let red = CGFloat((hexValue >> 16) & 0xFF) / 255.0
        let green = CGFloat((hexValue >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hexValue & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
struct GlobalTracking {
    private init(courses: [CourseWrapper]) {
        GlobalTracking.courses = courses
    }
    static var courses: [CourseWrapper] = []
    static var currentMinHeightForPageView: CGFloat = 0
    
    @ViewBuilder
    static func BackButton(binding: Binding<PresentationMode>, navigationPath: Binding<NavigationPath>) -> some View {
        BackButton(binding: binding, navigationPath: navigationPath, color: .white)
    }
    @ViewBuilder
    static func BackButton(binding: Binding<PresentationMode>, navigationPath: Binding<NavigationPath>, color: Color) -> some View {
        Button(action: {binding.wrappedValue.dismiss()}) {
            Image(systemName: "arrowshape.left.fill")
                .resizable()
                .frame(width: 40, height: 30)
                .foregroundStyle(color)
            
        }
        .contextMenu {
            ForEach(courses, id: \.id) { course in
                Button(action: {
                    navigationPath.wrappedValue = NavigationPath()
                    navigationPath.wrappedValue.append(course)
                    
                }, label: {
                    Text("\(course.course.name ?? "Missing Name")")
                }
                )
            }
        }
    }
}




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

/// longFormWithTime = January 1st, 1970, 12:00 AM
/// longForm = January 1st, 1970
/// shortForm = 1/1
/// mediumForm = Jan 1, 1970
/// mediumFormWithTime =  Jan 1, 1970 12:00 AM
enum formatDate : String {
    case longFormWithTime = "MMMM d'th', yyyy h:mma z"
    case longForm = "MMMM d'th', yyyy"
    case shortForm = "MM/dd"
    case mediumForm = "MMM d, yyyy"
    case mediuMFormWithTime = "MMM d, yyyy h:mm a"
    
}

/// formattedDate returns a String formatted from a Date object.
/// - Parameters:
///   - date: A Date object. By default, it is a new Date() instance.
///   - format: A formatDate enum. By default, it is the .shortForm case.
/// - Returns: A String formatted dependent on the format parameter.
func formattedDate(for date: Date = Date(), format: formatDate = formatDate.shortForm) -> String {
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = format.rawValue
    dateFormatter.locale = Locale.current
    dateFormatter.timeZone = TimeZone.current
    return dateFormatter.string(from: date)
}

enum ShapeType {
    case rectangle
    case circle
}


@ViewBuilder
func buildAsyncImage(urlString: String, imageWidth width: CGFloat, imageHeight height: CGFloat, color: Color = .clear, shape: ShapeType = .rectangle, colorOpacity opacity: Double = 1.0, placeShapeOnTop: Bool = false) -> some View {
 
    if let url = URL(string: urlString) {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: width, height: height)
            case .success(let image):
                ZStack {
                    switch shape {
                    case .rectangle:
                        image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width , height: height)
                        .clipShape(Rectangle())
                        if placeShapeOnTop {
                            Rectangle()
                                .frame(width: width , height: height)
                                .foregroundStyle(color).opacity(opacity)

                        }
                    case .circle:
                        image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width , height: height)
                        .clipShape(Circle())
                        if placeShapeOnTop {
                            Circle()
                                .frame(width: width , height: height)
                                .foregroundStyle(color).opacity(opacity)

                        }
                    }
                        
                }
                
            case .failure:
                Image(systemName: "exclamationmark.triangle.fill")
                    .frame(width: width, height: height)
            @unknown default:
                EmptyView()
            }
        }
        
    } else {
        switch shape {
        case .rectangle:
            Rectangle()
                .frame(width: width, height: height)
                .foregroundStyle(color)

        case .circle:
            Circle()
                .frame(width: width, height: height)
                .foregroundStyle(color)

        }
    }
}

extension Float {
    /// https://stackoverflow.com/questions/31390466/swift-how-to-remove-a-decimal-from-a-float-if-the-decimal-is-equal-to-0
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}



class HTMLRenderer {
    
    
    
    static func makeAttributedString(from html: String) -> AttributedString {
        let config = AttributedStringConverterConfiguration(
            font: UIFont.systemFont(ofSize: 16),
            monospaceFont: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular),
            fontMetrics: .default,
            color: UIColor.black,
            paragraphStyle: .default
        )

        
        let converter = AttributedStringConverter(configuration: config)
        let attributedString = try? AttributedString(converter.convert(html: html), including: \.uiKit)
        return attributedString!
    }
}
@ViewBuilder
func preparePageDisplay(page: any PageRepresentable) -> some View {
    preparePageDisplay(page: page, alignment: .leading)
}
@ViewBuilder
func preparePageDisplay(page: any PageRepresentable, alignment: TextAlignment) -> some View {
    ScrollView {
        Text(page.attributedText ?? "Could not load attributed text").multilineTextAlignment(alignment)
    }
}
