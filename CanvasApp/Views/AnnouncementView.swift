//
//  AnnouncementView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/14/24.
//

import SwiftUI

enum TimePeriod : String, CaseIterable{
    case today = "Today"
    case yesterday = "Yesterday"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case previously = "Previously"
}
struct AnnouncementView : View {
    
    
    var courseWrapper: CourseWrapper
    let loadAuthorData: Bool
    
    let avatarWidth: CGFloat = 40
    let avatarHeight: CGFloat = 40
    
    @State private var announcementGroupIsExpanded: Set<Int>
    @State private var individalAnnouncementIsExpanded: Set<Int>

    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding private var navigationPath: NavigationPath
    
    let color: Color
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        loadAuthorData = courseWrapper.course.announcements[0].author != nil
        _announcementGroupIsExpanded = State(initialValue: Set(TimePeriod.allCases.map{$0.hashValue}))
        _individalAnnouncementIsExpanded = State(initialValue: Set())
        self.color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
     
    }
    
    @State private var selectedAnnouncement: DiscussionTopic? = nil
    @State private var loadFullAnnouncementView: Bool = false
    @State private var expandedAnnouncementID: Int?
    
    @ViewBuilder
    private func buildAnnouncementFullView() -> some View {
        if var announcement = selectedAnnouncement {
            VStack {
                PageView(attributedContent: announcement.attributedText ?? NSAttributedString(string: "Failed to load NSAttributedString for announcement \(announcement.id)", attributes: nil)).id(announcement.id)
            }
        }
        
    }
    
    
    @ViewBuilder
    private func buildAnnouncementGlanceView(announcement: DiscussionTopic) -> some View {
        VStack {
            PageView(attributedContent: announcement.attributedText ?? NSAttributedString(string: "Failed to load NSAttributedString for announcement \(announcement.id)", attributes: nil)).id(announcement.id)
        }.frame(minHeight: GlobalTracking.currentMinHeightForPageView)
    }

    
    
    @ViewBuilder
    private func buildAnnouncement(timePeriod: TimePeriod) -> some View {
        let announcements = courseWrapper.course.datedAnnouncements[timePeriod]!
            ForEach(announcements) { announcement in
                let loadAuthorData = announcement.author != nil
                DisclosureGroup(isExpanded: Binding<Bool> (
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
                ),
                                content: {
                    VStack(alignment: .center) {
                        buildAnnouncementGlanceView(announcement: announcement)
                    }
                },
                                label: {
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .top) {
                            let authorURL: String? = announcement.author?.avatarURL
                            AsyncImageView(urlString: authorURL ?? "Missing", width: avatarWidth, height: avatarHeight)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(announcement.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.black)
                                HStack {
                                    if (loadAuthorData) {
                                        Text((announcement.author?.displayName!)!)
                                            .font(.footnote)
                                            .foregroundStyle(Color.black)
                                        Spacer()
                                        Text("\(formattedDate(for: announcement))")
                                            .font(.footnote)
                                            .foregroundStyle(Color.black)
                                    }
                                    
                                }
                               
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    
//    @ViewBuilder
//    private func announcementGroup(timePeriod:  TimePeriod) -> some View {
//        if let announcements = datedAnnouncements[timePeriod], !announcements.isEmpty {
//            VStack(spacing: 0) {
//                ForEach(announcements) { announcement in
//                    let isExpanded = Binding(
//                            get: {expandedAnnouncementID == announcement.id},
//                            set: {isExpanded in expandedAnnouncementID = isExpanded ? announcement.id  : nil}
//                        )
//                    DisclosureGroup(isExpanded: isExpanded)
//                    {
//                        if isExpanded.wrappedValue {
//                            VStack {
//                                Text("Posted on " + formattedDate(for: announcement))
//                                    .font(.caption)
//                                GeometryReader { geometry in
//                                    PageView(attributedContent: announcement.attributedText ?? NSAttributedString(string: "Failed to load NSAttributedString for announcement \(announcement.id)", attributes: nil)).id(announcement.id)
//                                        .padding()
//                                        .frame(minHeight: 300, maxHeight: geometry.size.height  )
//                                    
//                                }
//                                .frame(minHeight: 300)
//                                .padding(.bottom)
//                                
//                            }
//
//                        }
//                        
//                            
//                    } label: {
//                        HStack(alignment: .top, spacing: 8) {
//                            AsyncImageView(urlString: (announcement.author?.avatarURL) ?? "Missing", width: avatarWidth, height: avatarHeight)
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(announcement.title)
//                                    .font(.headline)
//                                    .multilineTextAlignment(.leading)
//                                    .foregroundStyle(Color.black)
//                                if (announcement.author?.displayName != nil) {
//                                    Text((announcement.author?.displayName!)!)
//                                        .font(.footnote)
//                                        .foregroundStyle(Color.black)
//                                }
//                            }
//                        }
//                    }.simultaneousGesture(
//                        LongPressGesture().onEnded { _ in
//                            selectedAnnouncement = announcement
//                            loadFullAnnouncementView = true
//                        }
//                    )
//                    .listRowInsets(EdgeInsets())
//                }
//                .listStyle(PlainListStyle())
//            }
//            .padding(.horizontal)
//        }
//    }
        var body: some View {
            VStack {
                buildAnnouncementList()
            }
            .navigationDestination(isPresented: $loadFullAnnouncementView, destination: {buildAnnouncementFullView()})
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GlobalTracking.BackButton(binding: presentationMode, navigationPath: $navigationPath)
                }
                ToolbarItem(placement: .principal) {
                    Text("Announcements")
                        .foregroundStyle(.white)
                        .font(.title)
                        .fontWeight(.heavy)
                }
            }
            .background(color)
            
        }
    }

//#Preview {
////    AnnouncementView()
//}
