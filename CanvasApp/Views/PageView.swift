//
//  PageView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/14/24.
//

import SwiftUI

struct PageView<T : PageRepresentable>: View {
    var courseWrapper: CourseWrapper
    var page: T
    var discussionTopic: DiscussionTopic?
    
    var author: User? = nil
    let alignment: TextAlignment
    let disableTitle: Bool
    
    var color: Color
    
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding private var navigationPath: NavigationPath
    
    init(courseWrapper: CourseWrapper, page: T, navigationPath: Binding<NavigationPath>, textAlignment alignment: TextAlignment, disableTitle: Bool) {
        self.courseWrapper = courseWrapper
        self.page = page
        self.color = HexToColor(courseWrapper.course.color)!
        self._navigationPath = navigationPath
        
        if (page is DiscussionTopic) {
            discussionTopic = page as? DiscussionTopic
            author = discussionTopic?.author
        }
        self.alignment = alignment
        self.disableTitle = disableTitle
        
        
    }
    init(courseWrapper: CourseWrapper, page: T, navigationPath: Binding<NavigationPath>, textAlignment: TextAlignment) {
        self.init(courseWrapper: courseWrapper, page: page, navigationPath: navigationPath, textAlignment: textAlignment, disableTitle: false)
    }
    var body : some View {
        VStack(alignment: .center) {
            HStack {
                if (author != nil) {
                    buildAsyncImage(urlString: author?.avatarURL ?? "No url", imageWidth: 50, imageHeight: 50)
                    Text(author?.displayName ?? "No display name")
                        .font(.title3)
                    
                }
                
            }
            if (discussionTopic != nil) {
                Text("\(formattedDate(for: discussionTopic?.postedAt ?? Date(), format: .longFormWithTime))")
                    .font(.subheadline)
                    .foregroundStyle(Color.black)
            }
            
            Text(page.title)
                .font(.headline)
            preparePageDisplay(page: page, alignment: alignment)
                .padding(.leading)
                .padding(.trailing)
            Spacer()
        }.padding(.top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlobalTracking.BackButton(binding: presentationMode, navigationPath: $navigationPath)
            }
            ToolbarItem(placement: .principal) {
                Text(page.title)
                    .foregroundStyle(.white)
                    .font(.subheadline)
                    .padding(.bottom)
            }

        }.toolbarBackground(color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
    
}








//#Preview {
//    let mockUser = User(
//        id: 1,
//        firstName: "John",
//        lastName: "Doe",
//        displayName: "John Doe",
//        pronouns: "he/him",
//        avatarURL: "https://example.com/avatar.jpg"
//    )
//
//    let mockDiscussionTopic = DiscussionTopic(
//        id: 1,
//        title: "Welcome to the Course",
//        body: "Hello everyone, welcome to the course!",
//        postedAt: Date(),
//        author: mockUser,
//        attributedText: nil
//    )
//
//    let mockCourse = Course(
//        name: "Introduction to SwiftUI",
//        courseCode: "SWIFT101",
//        id: 1,
//        image_download_url: "https://example.com/course.jpg",
//        term: nil,
//        color: "#3498db"
//    )
//
//    let mockCourseWrapper = CourseWrapper(course: mockCourse)
//    PageView(
//        courseWrapper: mockCourseWrapper,
//        page: mockDiscussionTopic,
//        navigationPath: .constant(NavigationPath())
//    )
//}
