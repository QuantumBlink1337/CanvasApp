//
//  GroupView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/23/24.
//

import Foundation
import SwiftUI



struct GroupView : View {
    private var group: Group
    @State private var showMenu = false

    @Binding private var navigationPath: NavigationPath
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    private var courseWrapper: CourseWrapper?
    private let color: Color
    
    var image_width: CGFloat = 200
    var image_height: CGFloat = 200
    
    init(group: Group, navigationPath: Binding<NavigationPath>, courseWrapper: CourseWrapper? = nil) {
        self.group = group
        self._navigationPath = navigationPath
        self.courseWrapper = courseWrapper
        self.color = if courseWrapper != nil {
            HexToColor(courseWrapper?.course.color ?? "#000000") ?? .blue
        }
        else {
            .blue
        }
            
    }
    
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack() {
                    VStack {
                        buildAsyncImage(urlString: courseWrapper?.course.image_download_url ?? "", imageWidth: geometry.size.width, imageHeight: image_height, color: HexToColor(courseWrapper?.course.color ?? "#000000") ?? .clear, shape: .rectangle, colorOpacity: 0.5, placeShapeOnTop: true)
                    }
                    VStack {
                        Text(group.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        Text(group.contextName ?? "Missing Contextual Name")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                    }
                    
                }
                ScrollView {
                    buildMenuButton(buttonTitle: "Announcements", buttonImageIcon: "megaphone", color: HexToColor(courseWrapper?.course.color ?? "#FFFFFF") ?? .black) {
//                        navigateToAnnouncementView = true
                    }
                    buildMenuButton(buttonTitle: "People", buttonImageIcon: "person.fill", color: HexToColor(courseWrapper?.course.color ?? "#FFFFFF") ?? .black) {
//                        navigateToPeopleView = true
                    }
                }

            }
           
            
            
        }
        .overlay {
            if showMenu {
                SideMenuView(isPresented: $showMenu, navigationPath: $navigationPath)
                    .zIndex(1) // Make sure it overlays above the content
                    .transition(.move(edge: .leading))
                    .frame(maxHeight: .infinity) // Full screen height
                    .ignoresSafeArea(edges: [.trailing])
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if (!showMenu) {
                    BackButton(binding: presentationMode, navigationPath: $navigationPath, color: color, action: {showMenu.toggle()})
                }
                else {
                    Color.clear.frame(height: 30)
                }
            }
        }

        
        
    }
}
