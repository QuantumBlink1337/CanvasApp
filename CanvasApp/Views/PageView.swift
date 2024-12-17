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
    
    let avatarWidth: CGFloat = 50
    let avatarHeight: CGFloat = 50
    
    
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
    
    @ViewBuilder
    private func buildAuthorHeader() -> some View {
        VStack(alignment: .leading) {
            
            HStack(alignment: .top) {
                let authorURL: String = discussionTopic?.author?.avatarURL ?? "Missing"
                buildAsyncImage(urlString: authorURL, imageWidth: avatarWidth, imageHeight: avatarHeight, shape: .circle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(discussionTopic?.author?.displayName ?? "Missing")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.black)
                    Text("Author | Test")
                    Text("Created: \(formattedDate(for: discussionTopic?.postedAt ?? Date(), format: formatDate.mediuMFormWithTime))")
                        .font(.footnote)
                        .foregroundStyle(Color.black)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            if (author != nil ) {
                buildAuthorHeader()
                    .padding(.leading)
            }
            Text(page.title)
                .font(.title)
                .padding(.leading)
            Divider()
            preparePageDisplay(page: page, alignment: alignment)
                .padding(.leading)
                .padding(.trailing)
            Divider()
            if (discussionTopic != nil) {
                if (discussionTopic?.lockedForComments == true) {
                    Text("This discussion is locked for comments.")
                        .font(.footnote)
                        .padding(.leading)
                }
                else {
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                        Text("Reply")
                    })
                }
            }
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
                    .font(.title2)
                    .fontWeight(.heavy)
            }

        }.toolbarBackground(color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
    
}

