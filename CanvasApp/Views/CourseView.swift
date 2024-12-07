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


struct ModuleView: View {
    var courseWrapper: CourseWrapper
    let iconTypeLookup: [ModuleItemType : String] = [ModuleItemType.assignment : "pencil.and.list.clipboard.rtl", ModuleItemType.discussion : "person.wave.2.fill", ModuleItemType.externalTool : "book.and.wrench.fill", ModuleItemType.externalURL : "globe", ModuleItemType.file : "folder.fill", ModuleItemType.page : "book.pages.fill", ModuleItemType.subheader : "list.dash.header.rectangle", ModuleItemType.quiz : "list.bullet.rectangle.portrait.fill"]
    
    @State private var isExpanded: Set<String>
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        
        _isExpanded = State(initialValue: Set(courseWrapper.course.modules.map{$0.name}))
        
        print(String(describing: courseWrapper.course.modules[0].items))
    }
    var body: some View {
        VStack {
            List(courseWrapper.course.modules) { module in
                Section(isExpanded: Binding<Bool> (
                    get: {
                        return isExpanded.contains(module.name)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            isExpanded.insert(module.name)
                        }
                        else {
                            isExpanded.remove(module.name)
                        }
                    }
                ),

                        content: {
                            ForEach(module.items!, id: \.id) { moduleItem in
                            HStack {
                                Image(systemName: iconTypeLookup[ModuleItemType(rawValue: moduleItem.type)!] ?? "questionmark.app.dashed")
                                    .frame(width: 20, height: 20)
                                Text(moduleItem.title)
                                    .padding(.leading, 15.0)

                            }
                        }

                },
                        header: {
                            Text(module.name)
                        }
                )
            }
            .listStyle(.sidebar)
            
        }
    }
}

struct AnnouncementView : View {
    var courseWrapper: CourseWrapper
    let loadAuthorData: Bool
    
    let avatarWidth: CGFloat = 25
    let avatarHeight: CGFloat = 25
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
       
        
        loadAuthorData = courseWrapper.course.announcements[0].author != nil
        print(String(describing: courseWrapper.course.announcements[0].author))
    }
    
    
    var body: some View {
        List(courseWrapper.course.announcements) { announcement in
            HStack {
                if let urlString = announcement.author?.avatarURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: avatarWidth, height: avatarHeight)
                        case .success(let image):
                            ZStack {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: avatarWidth , height: avatarHeight)
                                    .clipShape(Rectangle())
                                Rectangle()
                                    .frame(width: avatarWidth, height: avatarHeight)
                            }
                            
                        case .failure:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .frame(width: avatarWidth, height: avatarHeight)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                } else {
                    Circle()
                        .frame(width: avatarWidth, height: avatarHeight)
                }
                VStack {
                    Text(announcement.title)
                        .font(.headline)
                    if (loadAuthorData) {
                        Text("Author: " + (announcement.author?.displayName)!)
                        .font(.footnote)
                    }
                    
                }
            }
            
            
        }
    }
}


struct CourseView: View {
    var courseWrapper: CourseWrapper
    let color: Color
    var image_width: CGFloat = 200
    var image_height: CGFloat = 200
    let pageClient: PageClient
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        color = HexToColor(courseWrapper.course.color) ?? .accentColor
        pageClient = PageClient()
    }
    @State private var frontPageLoaded = false
    
    @State private var pageLoadFailed = false
    @State private var showAlert = false
    
    @State private var navigateToPageView = false
    @State private var navigateToModuleView = false
    @State private var navigateToAnnouncementView = false

    var body: some View {
        NavigationStack {
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
                        if (courseWrapper.course.pages.keys.contains(SpecificPage.FRONT_PAGE)) {
                            navigateToPageView = true
                        }
                        else if (!courseWrapper.course.modules.isEmpty) {
                            navigateToModuleView = true
                        }
//                        else {
//                            showAlert = true
//                        }
                    }) {
                        HStack() {
                            VStack {
                                Text("Home")
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                    .padding(/*@START_MENU_TOKEN@*/.trailing, 40.0/*@END_MENU_TOKEN@*/)
                                let page = if (courseWrapper.course.pages.keys.contains(SpecificPage.FRONT_PAGE)) {
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
                        if (frontPageLoaded) {
                            if let page = courseWrapper.course.pages[SpecificPage.FRONT_PAGE] {
                                PageView(page: page)
                            }
                            else {
                                Text("Page not available")
                            }
                        }
                        
                    }
                    .navigationDestination(isPresented: $navigateToModuleView) {
                        ModuleView(courseWrapper: courseWrapper)

                    }
                    ScrollView {
                        CourseSectionButton(buttonTitle: "Announcements", buttonImageIcon: "megaphone", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToAnnouncementView = true
                               
                        }
                        CourseSectionButton(buttonTitle: "Syllabus", buttonImageIcon: "list.bullet.clipboard", color: HexToColor(courseWrapper.course.color) ?? .black) {
                                print("Test button")
                        }
                        CourseSectionButton(buttonTitle: "Assignment", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                                print("Test button")
                        }
                        CourseSectionButton(buttonTitle: "Modules", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToModuleView = true
                        }
                        CourseSectionButton(buttonTitle: "Grades", buttonImageIcon: "scroll", color: HexToColor(courseWrapper.course.color) ?? .black) {
                                print("Test button")
                        }
                    }.navigationDestination(isPresented: $navigateToModuleView) {
                        ModuleView(courseWrapper: courseWrapper)
                    }
                    .navigationDestination(isPresented: $navigateToAnnouncementView) {
                        AnnouncementView(courseWrapper: courseWrapper)
                    }
                }
                    
    

            }

        }
        .task {
            do {
                if (!courseWrapper.course.pages.keys.contains(SpecificPage.FRONT_PAGE)) {
                    let page = try await pageClient.retrievePage(course_id: courseWrapper.course.id, page: SpecificPage.FRONT_PAGE)
                    courseWrapper.course.pages.updateValue(page, forKey: SpecificPage.FRONT_PAGE)
                    frontPageLoaded = true
                }
            }
            catch {
                print("Failed to load page \(error)")
                pageLoadFailed = true
            }
            
           
        }
    }
}

#Preview {
    CourseView(courseWrapper: CourseWrapper(course: Course(courseCode: "Test Code", id: 123456, term: Term(id: 1000, name: "2090 Fall Semester", startAt: nil, endAt: nil), color: "#123FAF")))
    
}


