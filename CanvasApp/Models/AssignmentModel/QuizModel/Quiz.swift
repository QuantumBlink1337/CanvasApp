//
//  Quiz.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/6/25.
//

import Foundation

struct Quiz : Assignable {
    var id: Int
    var title: String
    var body: String?
    var dueAt: Date?
    var lockedAt: Date?
    var attributedText: AttributedString?

    
    
    private enum CodingKeys : String, CodingKey {
        case id = "id"
        case title = "title"
        case body = "description"
        case dueAt = "due_at"
        case lockedAt = "lock_at"
        case attributedText
    }
    
    
    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       
       // Decode required properties
       self.id = try container.decode(Int.self, forKey: .id)
       self.title = try container.decode(String.self, forKey: .title)

       
       // Decode optional properties
       self.body = try container.decodeIfPresent(String.self, forKey: .body)
       self.dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
       self.lockedAt = try container.decodeIfPresent(Date.self, forKey: .lockedAt)
    
    
       self.attributedText = try container.decodeIfPresent(AttributedString.self, forKey: .attributedText)

    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encodeIfPresent(self.body, forKey: .body)
        try container.encodeIfPresent(self.dueAt, forKey: .dueAt)
        try container.encodeIfPresent(self.lockedAt, forKey: .lockedAt)
        try container.encodeIfPresent(self.attributedText, forKey: .attributedText)
    }
    
    
}



