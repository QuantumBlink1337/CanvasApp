//
//  DiscussionTopic.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/6/24.
//

import Foundation

enum TimePeriod : String, CaseIterable, Codable{
    case today = "Today"
    case yesterday = "Yesterday"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case previously = "Previously"
}

struct DiscussionTopic : Codable, Identifiable, PageRepresentable {
    var id: Int
    var title: String
    var body: String?
    var postedAt: Date?
    var author: User?
    var authorRole: EnrollmentType? = nil
    var lockedForComments: Bool
    
    var attributedText: AttributedString? = nil
    
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case body = "message"
        case postedAt = "posted_at"
        case author = "author"
        case lockedForComments = "locked"
        case attributedText
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
        self.postedAt = try container.decodeIfPresent(Date.self, forKey: .postedAt)
        self.author = try container.decodeIfPresent(User.self, forKey: .author)
        self.lockedForComments = try container.decode(Bool.self, forKey: .lockedForComments)
        self.attributedText = try container.decodeIfPresent(AttributedString.self, forKey: .attributedText)
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encodeIfPresent(self.body, forKey: .body)
        try container.encodeIfPresent(self.postedAt, forKey: .postedAt)
        try container.encodeIfPresent(self.author, forKey: .author)
        try container.encode(self.lockedForComments, forKey: .lockedForComments)
        try container.encodeIfPresent(self.attributedText, forKey: .attributedText)
    }
    
}
    
