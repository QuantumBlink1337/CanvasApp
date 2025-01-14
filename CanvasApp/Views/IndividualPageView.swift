//
//  PageView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/14/24.
//

import SwiftUI

struct IndividualPageView<T : PageRepresentable>: View {
    var page: T? = nil
    var discussionTopic: DiscussionTopic?
    let contextRepresentable: any ContextRepresentable
    var author: User? = nil
    let alignment: TextAlignment
    let disableTitle: Bool
    
    var color: Color
    
    let title: String
    let attributedText: AttributedString
    
    let avatarWidth: CGFloat = 50
    let avatarHeight: CGFloat = 50
    
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding private var navigationPath: NavigationPath
    
    @State private var showMenu = false

    
    init(contextRep: any ContextRepresentable, page: T, navigationPath: Binding<NavigationPath>, textAlignment alignment: TextAlignment, disableTitle: Bool) {
        self.contextRepresentable = contextRep
        self.page = page
        self.color = HexToColor(contextRepresentable.color)!
        self._navigationPath = navigationPath
        self.title = page.title
        if (page is DiscussionTopic) {
            discussionTopic = page as? DiscussionTopic
            author = discussionTopic?.author
        }
        self.alignment = alignment
        self.disableTitle = disableTitle
        self.attributedText = page.attributedText ?? AttributedString()
        
    }
    init(contextRep: any ContextRepresentable, page: T, navigationPath: Binding<NavigationPath>, textAlignment: TextAlignment) {
        self.init(contextRep: contextRep, page: page, navigationPath: navigationPath, textAlignment: textAlignment, disableTitle: false)
    }
    init(contextRep: any ContextRepresentable, attributedText: AttributedString, title: String, navigationPath: Binding<NavigationPath>, textAlignment: TextAlignment, disableTitle: Bool = false) {
        self.contextRepresentable = contextRep
        self.color = HexToColor(contextRepresentable.color)!
        self._navigationPath = navigationPath
        self.title = title
        self.alignment = textAlignment
        self.attributedText = attributedText
        self.disableTitle = disableTitle
        

    }
    
    @ViewBuilder
    private func buildAuthorHeader() -> some View {
        VStack(alignment: .leading) {
            
            HStack(alignment: .top) {
                let authorURL: String = discussionTopic?.author?.avatarURL ?? "Missing"
                buildAsyncImage(urlString: authorURL, imageWidth: avatarWidth, imageHeight: avatarHeight, shape: .circle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(discussionTopic?.author?.name ?? "Missing")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.black)
                    Text("Author | \(discussionTopic?.authorRole?.rawValue.replacingOccurrences(of: "Enrollment", with: "") ?? "Missing role")")
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
            Text(title)
                .font(.title)
                .padding(.leading)
            Divider()
            preparePageDisplay(attributedText: attributedText, alignment: alignment)
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
        }
        .padding(.top)
        .overlay {
            if showMenu {
                SideMenuView(isPresented: $showMenu, navigationPath: $navigationPath)
                    .zIndex(1) // Make sure it overlays above the content
                    .transition(.move(edge: .leading))
                    .frame(maxHeight: .infinity) // Full screen height
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if (!showMenu) {
                        BackButton(binding: presentationMode, navigationPath: $navigationPath, action: {showMenu.toggle()})

                    }
                    else {
                        Color.clear.frame(height: 30)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if (!showMenu) {
                        Text("\(page?.title ?? "Missing Title")")
                            .foregroundStyle(.white)
                            .font(.title)
                            .fontWeight(.heavy)
                    }
                    else {
                        Color.clear.frame(height: 30)

                    }
                }
        }.toolbarBackground(color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
    
}

