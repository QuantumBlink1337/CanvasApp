//
//  DiscussionTopicView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/2/25.
//

import SwiftUI

struct DiscussionTopicView: View {
    let avatarWidth: CGFloat = 40
    let avatarHeight: CGFloat = 40
    let contextRepresentable: any ContextRepresentable
    let discussionTopics: [CommentState : [DiscussionTopic]]
    
    @State private var discussionTopicGroupIsExpanded: Set<Int>
    @State private var individalDiscussionTopicIsExpanded: Set<Int>
    


    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding private var navigationPath: NavigationPath
    
    let color: Color
    
    init(contextRep: any ContextRepresentable, navigationPath: Binding<NavigationPath>) {
        self.contextRepresentable = contextRep
        self.discussionTopics = contextRep.discussionTopics
        _discussionTopicGroupIsExpanded = State(initialValue: Set(CommentState.allCases.map{$0.hashValue}))
        _individalDiscussionTopicIsExpanded = State(initialValue: Set())
        self.color = HexToColor(contextRepresentable.color) ?? .black
        self._navigationPath = navigationPath
     
    }
    
    @State private var selectedDiscussionTopic: DiscussionTopic? = nil
    @State private var loadFullDiscussionTopic: Bool = false
    @State private var expandedAnnouncementID: Int?
    
    @State private var showMenu = false

    
    @ViewBuilder
    private func buildDiscussionTopicFullView() -> some View {
        if let discussionTopic = selectedDiscussionTopic {
            VStack {
                PageView(contextRep: contextRepresentable, page: discussionTopic, navigationPath: $navigationPath, textAlignment: .leading)
            }
        }
        
    }
    
    
    @ViewBuilder
    private func buildDiscussionTopicGlanceView(announcement: DiscussionTopic) -> some View {
        VStack {
            
            preparePageDisplay(page: announcement, alignment: .leading)
            
        }
            
    }

    
    
    @ViewBuilder
    private func buildDiscussionTopic(commentState: CommentState) -> some View {
            ForEach(discussionTopics[commentState]!) { discussionTopic in
                let loadAuthorData = discussionTopic.author != nil
                let isExpanded = Binding<Bool> (
                    get: {
                        return individalDiscussionTopicIsExpanded.contains(discussionTopic.id)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            individalDiscussionTopicIsExpanded.insert(discussionTopic.id)
                        }
                        else {
                            individalDiscussionTopicIsExpanded.remove(discussionTopic.id)
                        }
                    }
                )
                DisclosureGroup(isExpanded: isExpanded,
                                
                            content: {
                    VStack(alignment: .center) {
                        buildDiscussionTopicGlanceView(announcement: discussionTopic)
                    }
                },
                                label: {
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .top) {
                            let authorURL: String = discussionTopic.author?.avatarURL ?? "Missing"
                            buildAsyncImage(urlString: authorURL, imageWidth: avatarWidth, imageHeight: avatarHeight, shape: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(discussionTopic.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.black)
                                HStack {
                                    if (loadAuthorData) {
                                        Text((discussionTopic.author?.name ?? "No author")!)
                                            .font(.footnote)
                                            .foregroundStyle(Color.black)
                                    }
                                    
                                    
                                }
                                Text("\(formattedDate(for: discussionTopic.postedAt ?? Date(), format: formatDate.longForm))")
                                    .font(.footnote)
                                    .foregroundStyle(Color.black)
                               
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.wrappedValue.toggle()
                            }
                        }
                    }
                    .simultaneousGesture(LongPressGesture().onEnded {_ in
                        selectedDiscussionTopic = discussionTopic
                        loadFullDiscussionTopic = true
                    })
                    
                }
                )
                .tint(color)
            }
    }
    
    
    @ViewBuilder
    private func buildDiscussionTopicList() -> some View {
        List {
            ForEach(CommentState.allCases, id: \.hashValue) { commentState in
                Section(isExpanded: Binding<Bool> (
                    get: {
                        return discussionTopicGroupIsExpanded.contains(commentState.hashValue)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            discussionTopicGroupIsExpanded.insert(commentState.hashValue)
                        }
                        else {
                            discussionTopicGroupIsExpanded.remove((commentState.hashValue))
                        }
                    }
                ),
                    
                content: {
                    buildDiscussionTopic(commentState: commentState)

                },
                header:
                    {
                    Text("\(commentState.rawValue)")
                        .font(.subheadline)
                        .fontWeight(.heavy)
                    }
                )
            }
        
        }
        .listStyle(.sidebar)
        .background(color)
        .padding(.top)
    }
    var body: some View {
        VStack {
            buildDiscussionTopicList()
        }
        .navigationDestination(isPresented: $loadFullDiscussionTopic, destination: {buildDiscussionTopicFullView()})
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
                        Text("Discussion Topics")
                            .foregroundStyle(.white)
                            .font(.title)
                            .fontWeight(.heavy)
                    }
                    else {
                        Color.clear.frame(height: 30)

                    }
                }
        }
        .background(color)
        
    }
}

//#Preview {
//    DiscussionTopicView()
//}
