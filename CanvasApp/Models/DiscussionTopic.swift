//
//  DiscussionTopic.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/6/24.
//

import Foundation

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
    }
    
}
    
