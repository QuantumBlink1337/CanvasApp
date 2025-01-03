//
//  CourseView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/29/24.
//

import SwiftUI

struct CourseSectionButton: View {
    let buttonTitle: String
    let buttonImageIcon: String
    let color: Color
    let action: (() -> Void)?
    
    var body: some View {
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
}

struct CourseView: View {
    var courseWrapper: CourseWrapper
    let color: Color
    var image_width: CGFloat = 200
    var image_height: CGFloat = 200
    let pageClient: PageClient
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    
    @State private var frontPageLoaded = false
    
    @State private var pageLoadFailed = false
    @State private var showAlert = false
    
    @State private var navigateToHomePage = false
    @State private var navigateToModuleView = false
    @State private var navigateToAnnouncementView = false
    @State private var navigateToAssignmentView = false
    @State private var navigateToSyllabusView = false
    @State private var navigateToPeopleView = false
    
    @State private var showMenu = false

    
    @State private var measuredHeight: CGFloat = 0
    
    @Binding private var navigationPath: NavigationPath
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        color = HexToColor(courseWrapper.course.color) ?? .accentColor
        pageClient = PageClient()
        self._navigationPath = navigationPath
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack() {
                    VStack {
                        buildAsyncImage(urlString: courseWrapper.course.image_download_url ?? "", imageWidth: geometry.size.width, imageHeight: image_height, color: HexToColor(courseWrapper.course.color) ?? .clear, shape: .rectangle, colorOpacity: 0.5, placeShapeOnTop: true)
                    }
                    VStack {
                        Text(courseWrapper.course.name ?? "Missing Name")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        Text(courseWrapper.course.term?.name ?? "Missing Term")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                    }
                    
                }

                
                ScrollView {
                    if (frontPageLoaded) {
                        CourseSectionButton(buttonTitle: "Home Page", buttonImageIcon: "house.fill", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToHomePage = true
                            
                        }
                    }
                    CourseSectionButton(buttonTitle: "Announcements", buttonImageIcon: "megaphone", color: HexToColor(courseWrapper.course.color) ?? .black) {
                        navigateToAnnouncementView = true
                        
                    }
                    if (courseWrapper.course.syllabusBody != nil) {
                        CourseSectionButton(buttonTitle: "Syllabus", buttonImageIcon: "list.bullet.clipboard", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToModuleView = false
                            navigateToHomePage = false
                            navigateToAnnouncementView = false
                            navigateToSyllabusView = true
                        }
                    }
                    CourseSectionButton(buttonTitle: "Modules", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                        navigateToModuleView = true
                        navigateToHomePage = false
                        navigateToAnnouncementView = false
                        navigateToAssignmentView = false
                    }
                    
                    CourseSectionButton(buttonTitle: "Assignments & Grades", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                        navigateToModuleView = false
                        navigateToHomePage = false
                        navigateToAnnouncementView = false
                        navigateToAssignmentView = true
                    }
                    CourseSectionButton(buttonTitle: "People", buttonImageIcon: "person.fill", color: HexToColor(courseWrapper.course.color) ?? .black) {
                        navigateToPeopleView = true
                    }

                }
                .navigationDestination(isPresented: $navigateToHomePage) {
                    if (courseWrapper.course.frontPage != nil) {
                        PageView(contextRep: courseWrapper.course, page: courseWrapper.course.frontPage!, navigationPath: $navigationPath, textAlignment: .center)
                    }
                }
                .navigationDestination(isPresented: $navigateToModuleView) {
                    
                    ModuleView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                }
                .navigationDestination(isPresented: $navigateToAnnouncementView) {
                    AnnouncementView(contextRep: courseWrapper.course, navigationPath: $navigationPath)
                }
                .navigationDestination(isPresented: $navigateToAssignmentView) {
                    AssignmentMasterView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                    
                }
                .navigationDestination(isPresented: $navigateToPeopleView) {
                    PeopleView(contextRep: courseWrapper.course, navigationPath: $navigationPath)
                    
                }
                .navigationDestination(isPresented: $navigateToSyllabusView) {
                    PageView<Page>(contextRep: courseWrapper.course, attributedText: courseWrapper.course.syllabusAttributedString, title: "Syllabus", navigationPath: $navigationPath, textAlignment: .leading)
                    
                }
            }
            .task {
                if (courseWrapper.course.frontPage != nil) {
                    frontPageLoaded = true
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
    
