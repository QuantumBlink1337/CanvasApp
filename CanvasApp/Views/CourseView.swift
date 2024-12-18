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
                    
                    Button(action:  {
                        if  (frontPageLoaded) {
                            navigateToHomePage = true
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
                    .navigationDestination(isPresented: $navigateToHomePage) {
                        if (courseWrapper.course.frontPage != nil) {
                            PageView(courseWrapper: courseWrapper, page: courseWrapper.course.frontPage!, navigationPath: $navigationPath, textAlignment: .center)
                        }
                    }
                    ScrollView {
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
                       
//                        CourseSectionButton(buttonTitle: "Grades", buttonImageIcon: "scroll", color: HexToColor(courseWrapper.course.color) ?? .black) {
//                            print("Test button")
//                        }
                    }.navigationDestination(isPresented: $navigateToModuleView) {
                        
                        ModuleView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                    }
                    .navigationDestination(isPresented: $navigateToAnnouncementView) {
                        AnnouncementView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                    }
                    .navigationDestination(isPresented: $navigateToAssignmentView) {
                        AssignmentMasterView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                        
                    }
                    .navigationDestination(isPresented: $navigateToPeopleView) {
                        PeopleView(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                        
                    }
                    .navigationDestination(isPresented: $navigateToSyllabusView) {
                        PageView<Page>(courseWrapper: courseWrapper, attributedText: courseWrapper.course.syllabusAttributedString, title: "Syllabus", navigationPath: $navigationPath, textAlignment: .leading)
                        
                    }
                }
                .task {
                    if (courseWrapper.course.frontPage != nil) {
                        frontPageLoaded = true
                    }
                }
                
                
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GlobalTracking.BackButton(binding: presentationMode, navigationPath: $navigationPath, color: color)
                }
//                ToolbarItem(placement: .principal) {
//                    Text("Announcements")
//                        .foregroundStyle(.white)
//                        .font(.title)
//                        .fontWeight(.heavy)
//                }
            }
//            .background(color)
            
        }
    }
    
//    #Preview {
//        CourseView(courseWrapper: CourseWrapper(course: Course(courseCode: "Test Code", id: 123456, term: Term(id: 1000, name: "2090 Fall Semester", startAt: nil, endAt: nil), color: "#123FAF")))
//        
//    }
