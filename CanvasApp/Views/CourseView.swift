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
    }
    var body: some View {
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
            .onAppear {
                print("Modules appeared")
            }
            .onDisappear() {
                print("Modules disappeared")
            }
            
        
    }
}
enum TimePeriod {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case previously
}
struct AnnouncementView : View {
    private func prepareAnnouncements(from announcements: [DiscussionTopic]) -> [TimePeriod : [DiscussionTopic]] {
        var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [:]
        let timePeriods: [TimePeriod] = [.today, .yesterday, .lastWeek, .lastMonth, .previously]
        var removableAnnouncements = announcements
        for timePeriod in timePeriods {
            var announcementsInPeriod: [DiscussionTopic]
            switch timePeriod {
            case .today:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfDay = Calendar.current.startOfDay(for: Date())
                        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
//                        print("Start of day" + String(describing: startOfDay))
//                        print("end of day" + String(describing: endOfDay))
                        return postedAt >= startOfDay && postedAt < endOfDay
                    }
                    return false
                }
            case .yesterday:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!
//                        print("start of yesterday" + String(describing: startOfYesterday))
//                        print("end of yesterday" + String(describing: endOfYesterday))

                        return postedAt >= startOfYesterday && postedAt < endOfYesterday
                    }
                    return false
                }
            case .lastWeek:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
                        let startOfLastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
                        let endOfLastWeek = Calendar.current.date(byAdding: .day, value: -1, to: startOfWeek)!
//                        print("start of last week" + String(describing: startOfLastWeek))
//                        print("end of last week" + String(describing: endOfLastWeek))


                        return postedAt >= startOfLastWeek && postedAt <= endOfLastWeek
                    }
                    return false
                }
                
            case .lastMonth:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        // Get the first day of the current month
                        let firstOfCurrentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
                        // Subtract 1 month to get the first day of the previous month
                        let firstOfPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstOfCurrentMonth)!
                        // Get the last day of the previous month by subtracting 1 day from the first of the current month
                        let lastOfPreviousMonth = Calendar.current.date(byAdding: .day, value: -1, to: firstOfCurrentMonth)!
//                        print("first of prev month" + String(describing: firstOfPreviousMonth))
//                        print("last of prev month" + String(describing: lastOfPreviousMonth    ))


                        return postedAt >= firstOfPreviousMonth && postedAt <= lastOfPreviousMonth
                    }
                    return false
                }
            case .previously:
                announcementsInPeriod = removableAnnouncements
            }
            datedAnnouncements[timePeriod] = announcementsInPeriod
                removableAnnouncements.removeAll { announcement in
                    announcementsInPeriod.contains(where: {$0.id == announcement.id})
                }
            
            
        }
        return datedAnnouncements
    }
    
    var courseWrapper: CourseWrapper
    let loadAuthorData: Bool
    
    let avatarWidth: CGFloat = 40
    let avatarHeight: CGFloat = 40
    
    var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [ : ]
    
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        loadAuthorData = courseWrapper.course.announcements[0].author != nil
        self.datedAnnouncements = prepareAnnouncements(from: courseWrapper.course.announcements)
    }
    
    @State private var selectedAnnouncement: DiscussionTopic? = nil
    @State private var loadFullAnnouncementView: Bool = false
    @State private var expandedAnnouncementID: Int?
    
    
    
    
    @ViewBuilder
    private func announcementGroup(timePeriod:  TimePeriod) -> some View {
        if let announcements = datedAnnouncements[timePeriod], !announcements.isEmpty {
            VStack {
                List(announcements) { announcement in
                    let isExpanded = Binding(
                            get: {expandedAnnouncementID == announcement.id},
                            set: {isExpanded in expandedAnnouncementID = isExpanded ? announcement.id  : nil}
                        )
                    DisclosureGroup(isExpanded: isExpanded)
                    {
                        if isExpanded.wrappedValue {
                            PageView(attributedContent: announcement.attributedText ?? NSAttributedString(string: "Failed to load NSAttributedString for announcement \(announcement.id)", attributes: nil)).id(announcement.id)
                                .padding()
                                .frame(minHeight: 300)
                        }
                        
                            
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
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
                                                .clipShape(Circle())
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
                .navigationDestination(isPresented: $loadFullAnnouncementView) {
                    if let selectedAnnouncement = selectedAnnouncement {
                            PageView(attributedContent: selectedAnnouncement.attributedText ?? NSAttributedString(
                                string: "Failed to load NSAttributedString for announcement \(String(describing: selectedAnnouncement.id))"))
                            .navigationTitle(String(selectedAnnouncement.title))
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }.padding(.trailing)
            }.frame(minHeight: CGFloat(announcements.count) * 60)

                
            
        }
    }
        var body: some View {
            VStack {
                Text("Announcements")
                    .font(.title)
                    .fontWeight(.heavy)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                            Text("Today")
                                .font(.subheadline)
                            
                            announcementGroup(timePeriod: .today)
//                            .frame(minHeight: 100)
                            Text("Yesterday")
                                .font(.subheadline)
                            announcementGroup(timePeriod: .yesterday)
//                            .frame(minHeight: 100)
                            Text("Last Week")
                                .font(.subheadline)
                            announcementGroup(timePeriod: .lastWeek)
//                            .frame(minHeight: 100)

                            Text("Last Month")
                                .font(.subheadline)
                            announcementGroup(timePeriod: .lastMonth)
//                            .frame(minHeight: 100)
                            Text("Previously")
                                .font(.subheadline)
                            announcementGroup(timePeriod: .previously)
//                            .frame(minHeight: 100)
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
        
        @State private var frontPageLoaded = false
        
        @State private var pageLoadFailed = false
        @State private var showAlert = false
        
        @State private var navigateToPageView = false
        @State private var navigateToModuleView = false
        @State private var navigateToAnnouncementView = false
        
        @State private var measuredHeight: CGFloat = 0
        
        init(courseWrapper: CourseWrapper) {
            self.courseWrapper = courseWrapper
            color = HexToColor(courseWrapper.course.color) ?? .accentColor
            pageClient = PageClient()
            
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
                            print("Test button")
                        }
                        CourseSectionButton(buttonTitle: "Modules", buttonImageIcon: "pencil.and.list.clipboard.rtl", color: HexToColor(courseWrapper.course.color) ?? .black) {
                            navigateToModuleView = true
                            navigateToPageView = false
                            navigateToAnnouncementView = false
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
                .task {
                    if (courseWrapper.course.frontPage != nil) {
                        frontPageLoaded = true
                    }
                }
                
                
            }
            
            
        }
    }
    
    #Preview {
        CourseView(courseWrapper: CourseWrapper(course: Course(courseCode: "Test Code", id: 123456, term: Term(id: 1000, name: "2090 Fall Semester", startAt: nil, endAt: nil), color: "#123FAF")))
        
    }
