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
    
    static let avatarWidth: CGFloat = 40
    static let avatarHeight: CGFloat = 40
    
    
}


/// Builds a View intended for use as the "nav menu button" for the Toolbar.
/// - Parameters:
///   - binding: A Binding to the PresentationMode of the application.
///   - navigationPath: A Binding to the current NavigationPath being used by the NavigationStack of the calling code.
///   - color: The preferred color of the button image.
///   - action: A closure to be invoked on pressing the button.
/// - Returns: Some View representing a Button.
@ViewBuilder
func BackButton(binding: Binding<PresentationMode>, navigationPath: Binding<NavigationPath>, color: Color = .white, action: (() -> Void)? = nil) -> some View {
    Button(action: {
        action?()
    }) {
        Image(systemName: "line.3.horizontal")
            .resizable()
            .frame(width: 30, height: 30)
            .foregroundStyle(color)
        
    }

}
struct SideMenuView: View {
    @Binding var isPresented: Bool
    @GestureState private var dragOffset = CGSize.zero

    private let swipeThreshold: CGFloat = 20 // Distance to trigger swipe-to-dismiss
    private let menuWidth: CGFloat = 1200
    
    @Binding var navigationPath: NavigationPath

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.gray.opacity(0.3)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .ignoresSafeArea(edges: [.bottom, .trailing])

                    .allowsHitTesting(isPresented) // Prevent background interaction when menu is not shown
                VStack(alignment: .leading) {
                    HStack {
                        let authorURL: String = MainUser.selfUser?.avatarURL ?? "Missing"
                        buildAsyncImage(urlString: authorURL, imageWidth: 65, imageHeight: 65, shape: .circle)
                        Text("Hi, \(MainUser.selfUser?.firstName ?? "Missing name")")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .padding(.leading)
                    .padding(.trailing)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(MainUser.selfCourseWrappers) { courseWrapper in
                                Button(action: {
                                    $navigationPath.wrappedValue = NavigationPath()
                                    $navigationPath.wrappedValue.append(courseWrapper)
                                    isPresented = false
                                },
                                       
                                    label: {
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 240, height: 60)
                                            .foregroundStyle(HexToColor(courseWrapper.course.color) ?? .clear)
                                        Text("\(courseWrapper.course.name ?? "Missing name")")
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                            .font(.headline)
                                            .padding(.leading)
                                            .padding(.trailing)
                                    }
                                        
                                }
                                )
                                .frame(width: 240)
                                .padding(.leading)
                                .padding(.trailing)
                            }
                        }
                    }
                }
                .background(.thinMaterial)
            }
            .frame(width: menuWidth, height: geometry.size.height, alignment: .topLeading) // Full height based on GeometryReader
            .shadow(radius: 10)
            .offset(x: isPresented ? max(dragOffset.width, 0) : -menuWidth) // Restrict dragging to the right// Off-screen when not presented and allows drag to update offset
            .animation(.easeInOut, value: isPresented)
            .simultaneousGesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        // Track the drag offset
                        if (value.translation.width < 0) {
                            state = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -swipeThreshold { // If swipe crosses the threshold, dismiss the menu
                            withAnimation {
                                isPresented = false
                            }
                        } else { // If not, reset the menu to its original position
                            withAnimation {
                                isPresented = true
                            }
                        }
                    }
            )
            .contentShape(Rectangle()) // Ensure the entire area of the menu is tappable and draggable
            .ignoresSafeArea(edges: [.bottom, .trailing])
        }
        .shadow(radius: 20)
    }
}



struct CustomNavigationStack<Content: View>: View {
    @ViewBuilder var content: Content
    
    @Binding var path: NavigationPath
    
    @State private var interactivePopGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer()
        gesture.name = UUID().uuidString
        gesture.edges = UIRectEdge.left
        gesture.isEnabled = true
        return gesture
    }()
    
    var body: some View {
        NavigationStack(path: $path) {
            content
                .background {
                    AttachPopGestureView(gesture: $interactivePopGestureRecognizer)
                }
        }
    }
}

// https://medium.com/@yunchingtan/back-swipe-gesture-missing-when-using-swiftui-custom-back-button-0873f20be61f
// modified the custom navigation stack to take a link binding


struct AttachPopGestureView: UIViewRepresentable {
    @Binding var gesture: UIScreenEdgePanGestureRecognizer
    
    func makeUIView(context: Context) -> some UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            if let parentVC = uiView.parentViewController {
                if let navigationController = parentVC.navigationController {
                    
                    // To prevent duplication
                    guard !(navigationController.view.gestureRecognizers?
                        .contains(where: {$0.name == gesture.name}) ?? true) else { return }
                
                    navigationController.addInteractivePopGesture(gesture)
                }
            }
        }
    }
}



//MARK: - Helper
fileprivate extension UINavigationController {
    func addInteractivePopGesture(_ gesture: UIPanGestureRecognizer) {
        guard let gestureSelector = interactivePopGestureRecognizer?.value(forKey: "targets") else { return }
        
        gesture.setValue(gestureSelector, forKey: "targets")
        view.addGestureRecognizer(gesture)
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        sequence(first: self) { $0.next }.first(where: { $0 is UIViewController }) as? UIViewController
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
func buildAsyncImage(urlString: String, imageWidth width: CGFloat, imageHeight height: CGFloat, color: Color = .clear, shape: ShapeType = .rectangle, colorOpacity opacity: Double = 1.0, placeShapeOnTop: Bool = false, isAvatar: Bool = false) -> some View {
 
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
                switch shape {
                case .rectangle:
                    Rectangle()
                        .frame(width: width, height: height)
                        .foregroundStyle(color)

                case .circle:
                    if (isAvatar) {
                        
                        Image(systemName: "person.crop.circle")
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
                    else {
                        Circle()
                            .frame(width: width, height: height)
                            .foregroundStyle(color)
                    }
                }
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
@ViewBuilder
func buildMenuButton(buttonTitle: String, buttonImageIcon: String, color: Color, action: (() -> Void)?) -> some View {
    Button(action: {
        action?()
    }) {
        HStack {
            Image(systemName: buttonImageIcon)
                .padding(.trailing, 40)
                .padding(.leading, 50)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
            Text(buttonTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: 40, alignment: .leading)
        
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
func preparePageDisplay(page: any PageRepresentable, alignment: TextAlignment = .leading) -> some View {
    preparePageDisplay(attributedText: page.attributedText ?? AttributedString(), alignment: .leading)
}

@ViewBuilder
func preparePageDisplay(attributedText: AttributedString, alignment: TextAlignment = .center) -> some View {
    ScrollView {
        Text(attributedText).multilineTextAlignment(alignment)
    }
}
