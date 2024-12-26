//
//  AnnouncementView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/14/24.
//

import SwiftUI


struct AnnouncementView : View {
    
    
    var courseWrapper: CourseWrapper
    
    let avatarWidth: CGFloat = 40
    let avatarHeight: CGFloat = 40
    
    @State private var announcementGroupIsExpanded: Set<Int>
    @State private var individalAnnouncementIsExpanded: Set<Int>

    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding private var navigationPath: NavigationPath
    
    let color: Color
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        _announcementGroupIsExpanded = State(initialValue: Set(TimePeriod.allCases.map{$0.hashValue}))
        _individalAnnouncementIsExpanded = State(initialValue: Set())
        self.color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
     
    }
    
    @State private var selectedAnnouncement: DiscussionTopic? = nil
    @State private var loadFullAnnouncementView: Bool = false
    @State private var expandedAnnouncementID: Int?
    
    @State private var showMenu = false

    
    @ViewBuilder
    private func buildAnnouncementFullView() -> some View {
        if let announcement = selectedAnnouncement {
            VStack {
                PageView(courseWrapper: courseWrapper, page: announcement, navigationPath: $navigationPath, textAlignment: .leading)
            }
        }
        
    }
    
    
    @ViewBuilder
    private func buildAnnouncementGlanceView(announcement: DiscussionTopic) -> some View {
        VStack {
            
            preparePageDisplay(page: announcement, alignment: .leading)
            
        }
            
    }

    
    
    @ViewBuilder
    private func buildAnnouncement(timePeriod: TimePeriod) -> some View {
        let announcements = courseWrapper.course.datedAnnouncements[timePeriod]!
            ForEach(announcements) { announcement in
                let loadAuthorData = announcement.author != nil
                let isExpanded = Binding<Bool> (
                    get: {
                        return individalAnnouncementIsExpanded.contains(announcement.id)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            individalAnnouncementIsExpanded.insert(announcement.id)
                        }
                        else {
                            individalAnnouncementIsExpanded.remove(announcement.id)
                        }
                    }
                )
                DisclosureGroup(isExpanded: isExpanded,
                                
                            content: {
                    VStack(alignment: .center) {
                        buildAnnouncementGlanceView(announcement: announcement)
                    }
                },
                                label: {
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .top) {
                            let authorURL: String = announcement.author?.avatarURL ?? "Missing"
                            buildAsyncImage(urlString: authorURL, imageWidth: avatarWidth, imageHeight: avatarHeight, shape: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(announcement.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.black)
                                HStack {
                                    if (loadAuthorData) {
                                        Text((announcement.author?.name ?? "No author")!)
                                            .font(.footnote)
                                            .foregroundStyle(Color.black)
                                    }
                                    
                                    
                                }
                                Text("\(formattedDate(for: announcement.postedAt ?? Date(), format: formatDate.longForm))")
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
                        selectedAnnouncement = announcement
                        loadFullAnnouncementView = true
                    })
                    
                }
                )
                .tint(HexToColor(courseWrapper.course.color))
            }
    }
    
    
    @ViewBuilder
    private func buildAnnouncementList() -> some View {
        List {
            ForEach(TimePeriod.allCases, id: \.hashValue) { timePeriod in
                Section(isExpanded: Binding<Bool> (
                    get: {
                        return announcementGroupIsExpanded.contains(timePeriod.hashValue)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            announcementGroupIsExpanded.insert(timePeriod.hashValue)
                        }
                        else {
                            announcementGroupIsExpanded.remove((timePeriod.hashValue))
                        }
                    }
                ),
                    
                content: {
                    buildAnnouncement(timePeriod: timePeriod)

                },
                header:
                    {
                    Text("\(timePeriod.rawValue)")
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
            buildAnnouncementList()
        }
        .navigationDestination(isPresented: $loadFullAnnouncementView, destination: {buildAnnouncementFullView()})
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
                        Text("Announcements")
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
////    AnnouncementView()
//}
