//
//  AnnouncementView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/14/24.
//

import SwiftUI

enum TimePeriod : CaseIterable{
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case previously
}
struct AnnouncementView : View {
    
    
    var courseWrapper: CourseWrapper
    let loadAuthorData: Bool
    
    let avatarWidth: CGFloat = 40
    let avatarHeight: CGFloat = 40
    
    
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        loadAuthorData = courseWrapper.course.announcements[0].author != nil
     
    }
    
    @State private var selectedAnnouncement: DiscussionTopic? = nil
    @State private var loadFullAnnouncementView: Bool = false
    @State private var expandedAnnouncementID: Int?
    
    
    
    
    @ViewBuilder
    private func announcementGroup(timePeriod:  TimePeriod) -> some View {
        if let announcements = datedAnnouncements[timePeriod], !announcements.isEmpty {
            VStack(spacing: 0) {
                ForEach(announcements) { announcement in
                    let isExpanded = Binding(
                            get: {expandedAnnouncementID == announcement.id},
                            set: {isExpanded in expandedAnnouncementID = isExpanded ? announcement.id  : nil}
                        )
                    DisclosureGroup(isExpanded: isExpanded)
                    {
                        if isExpanded.wrappedValue {
                            VStack {
                                Text("Posted on " + formattedDate(for: announcement))
                                    .font(.caption)
                                GeometryReader { geometry in
                                    PageView(attributedContent: announcement.attributedText ?? NSAttributedString(string: "Failed to load NSAttributedString for announcement \(announcement.id)", attributes: nil)).id(announcement.id)
                                        .padding()
                                        .frame(minHeight: 300, maxHeight: geometry.size.height  )
                                    
                                }
                                .frame(minHeight: 300)
                                .padding(.bottom)
                                
                            }

                        }
                        
                            
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            AsyncImageView(urlString: (announcement.author?.avatarURL) ?? "Missing", width: avatarWidth, height: avatarHeight)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(announcement.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.black)
                                if (announcement.author?.displayName != nil) {
                                    Text((announcement.author?.displayName!)!)
                                        .font(.footnote)
                                        .foregroundStyle(Color.black)
                                }
                            }
                        }
                    }.simultaneousGesture(
                        LongPressGesture().onEnded { _ in
                            selectedAnnouncement = announcement
                            loadFullAnnouncementView = true
                        }
                    )
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(PlainListStyle())
            }
            .padding(.horizontal)
        }
    }
        var body: some View {
            VStack {
                Text("Announcements")
                    .font(.title)
                    .fontWeight(.heavy)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Today")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.leading)
                            announcementGroup(timePeriod: .today)
                        }
                        Group {
                            Text("Yesterday")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.leading)
                            announcementGroup(timePeriod: .yesterday)
                        }
                        Group {
                            Text("Last Week")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.leading)
                            announcementGroup(timePeriod: .lastWeek)
                        }
                        Group {
                            Text("Last Month")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.leading)
                            announcementGroup(timePeriod: .lastMonth)
                        }
                        Group {
                            Text("Previously")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.leading)
                            announcementGroup(timePeriod: .previously)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
            .navigationDestination(isPresented: $loadFullAnnouncementView) {
                if let selectedAnnouncement = selectedAnnouncement {
                    VStack {
                        PageView(attributedContent: selectedAnnouncement.attributedText ?? NSAttributedString(
                            string: "Failed to load NSAttributedString for announcement \(String(describing: selectedAnnouncement.id))"))
                        }
                        .navigationTitle(String(selectedAnnouncement.title))
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

//#Preview {
////    AnnouncementView()
//}
