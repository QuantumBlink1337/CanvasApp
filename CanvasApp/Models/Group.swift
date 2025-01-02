//
//  Group.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/22/24.
//

import Foundation

enum GroupContextType: String, Codable {
    case course = "Course"
    case account = "Account"

}



struct Group: ContextRepresentable {
    var id: Int
    var name: String?
    var description: String?
    var color: String = "#000000"

    var membersCount: Int
    var avatarURL: String?
    var contextType: GroupContextType
    
    var courseID: Int?
    var contextName: String?
    
    var accountID: Int?
    
    var users: [User]
    var announcements: [DiscussionTopic]
    var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [ : ]
    
    enum CodingKeys : String, CodingKey {
        case id
        case name
        case description
        case membersCount = "members_count"
        case avatarURL = "avatar_url"
        case contextType = "context_type"
        
        case courseID = "course_id"
        case contextName = "context_name"
        case accountID = "account_id"
        case users
        case announcements
    }
    
    mutating func sortAnnouncementsByRecency()  {
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
        self.datedAnnouncements = datedAnnouncements
    }

    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        self.membersCount = try container.decode(Int.self, forKey: .membersCount)
        self.avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        
        self.contextType = try container.decode(GroupContextType.self, forKey: .contextType)
        self.courseID = try container.decodeIfPresent(Int.self, forKey: .courseID)
        
        self.contextName = try container.decodeIfPresent(String.self, forKey: .contextName)
        self.accountID  = try container.decodeIfPresent(Int.self, forKey:   .accountID)
        self.users = try container.decodeIfPresent([User].self, forKey: .users) ?? []
        self.announcements = try container.decodeIfPresent([DiscussionTopic].self, forKey: .announcements) ?? []
        
        
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encodeIfPresent(self.description, forKey: .description)
        try container.encode(self.membersCount, forKey: .membersCount)
        try container.encodeIfPresent(self.avatarURL, forKey: .avatarURL)
        try container.encode(self.contextType, forKey: .contextType)
        try container.encodeIfPresent(self.courseID, forKey: .courseID)
        try container.encodeIfPresent(self.contextName, forKey: .contextName)
        try container.encodeIfPresent(self.accountID, forKey: .accountID)
        try container.encode(self.users, forKey: .users)
        try container.encode(self.announcements, forKey: .announcements)
    }
    
    
}
