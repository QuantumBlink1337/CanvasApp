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
        
        @State private var frontPageLoaded = false
        
        @State private var pageLoadFailed = false
        @State private var showAlert = false
        
        @State private var navigateToPageView = false
        @State private var navigateToModuleView = false
        @State private var navigateToAnnouncementView = false
        @State private var navigateToAssignmentView = false

        
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
                            if let urlString = courseWrapper.course.image_download_url, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: geometry.size.width, height: image_width)
                                    case .success(let image):
                                        ZStack {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: geometry.size.width , height: image_height)
                                                .clipShape(Rectangle())
                                            Rectangle()
                                                .frame(width: geometry.size.width, height: image_height)
                                            
                                                .foregroundStyle(color.opacity(0.5))
                                        }
                                        
                                    case .failure:
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(color)
                                            .frame(width: geometry.size.width, height: image_height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                
                            } else {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: image_height).foregroundStyle(color)
                            }
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
                    
                    Button(action:  {
                        if  (frontPageLoaded) {
                            navigateToPageView = true
                        }
                        else if (!courseWrapper.course.modules.isEmpty) {
                            navigateToModuleView = true
                        }
                    }) {
                        HStack() {
                            VStack {
                                Text("Home")
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                    .padding(/*@START_MENU_TOKEN@*/.trailing, 40.0/*@END_MENU_TOKEN@*/)
                                let page = if (frontPageLoaded) {
                                    "Welcome Page"
                                }
                                else {
                                    "Modules"
                                }
                                Text(page)
                                    .font(.subheadline)
                                    .padding(.trailing, 40.0)
                            }
                            
                            
                            
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .padding(.leading, 40.0)
                            
                        }
                        .frame(width: geometry.size.width / 1.15)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 2).shadow(radius: 50))
                    }
                    .alert("Page not available", isPresented: $showAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("Requested page could not be found")
                    }
                    .navigationDestination(isPresented: $navigateToPageView) {
                        if (courseWrapper.course.frontPage != nil) {
                            PageView(attributedContent: courseWrapper.course.frontPage!.attributedText! )
                            
                        }
                    }
                    ScrollView {
                        CourseSectionButton(buttonTitle: "Announcements", buttonImageIcon: "megaphone", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToAnnouncementView = true
                            
                        }
                        CourseSectionButton(buttonTitle: "Syllabus", buttonImageIcon: "list.bullet.clipboard", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            print("Test button")
                        }
                        CourseSectionButton(buttonTitle: "Assignment", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToModuleView = false
                            navigateToPageView = false
                            navigateToAnnouncementView = false
                            navigateToAssignmentView = true
                        }
                        CourseSectionButton(buttonTitle: "Modules", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToModuleView = true
                            navigateToPageView = false
                            navigateToAnnouncementView = false
                            navigateToAssignmentView = false
                        }
                        CourseSectionButton(buttonTitle: "Grades", buttonImageIcon: "scroll", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            print("Test button")
                        }
                    }.navigationDestination(isPresented: $navigateToModuleView) {
                        
                        ModuleView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                    }
                    .navigationDestination(isPresented: $navigateToAnnouncementView) {
                        AnnouncementView(courseWrapper: courseWrapper)
                    }
                    .navigationDestination(isPresented: $navigateToAssignmentView) {
                        AssignmentMasterView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                        
                    }
                }
                .task {
                    if (courseWrapper.course.frontPage != nil) {
                        frontPageLoaded = true
                    }
                }
                
                
            }
            
            
        }
    }
    
//    #Preview {
//        CourseView(courseWrapper: CourseWrapper(course: Course(courseCode: "Test Code", id: 123456, term: Term(id: 1000, name: "2090 Fall Semester", startAt: nil, endAt: nil), color: "#123FAF")))
//        
//    }
