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
    var people: [EnrollmentType : [User]] = [ : ]
    
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
        case people
        case datedAnnouncements
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
        self.people = try container.decodeIfPresent([EnrollmentType : [User]].self, forKey: .people) ?? [ : ]
        self.datedAnnouncements = try container.decodeIfPresent([TimePeriod: [DiscussionTopic]].self, forKey: .datedAnnouncements) ?? [ : ]

        
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
        try container.encode(self.people, forKey: .people)
        try container.encode(self.datedAnnouncements, forKey: .datedAnnouncements)
    }
    
    
}
