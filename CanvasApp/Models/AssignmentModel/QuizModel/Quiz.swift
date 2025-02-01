//
//  Quiz.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/6/25.
//

import Foundation

struct Quiz : Assignable {
    static func == (lhs: Quiz, rhs: Quiz) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.dueAt == rhs.dueAt && lhs.lockedAt == rhs.lockedAt && lhs.attributedText == rhs.attributedText
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(dueAt)
        hasher.combine(lockedAt)
        hasher.combine(attributedText)
    }
    
   
    var id: Int
    var title: String
    var body: String?
    var dueAt: Date?
    var lockedAt: Date?
    var allowedAttempts: Int
    var attributedText: AttributedString?
    var submissions: [QuizSubmission] = []
	
    
    
    private enum CodingKeys : String, CodingKey {
        case id = "id"
        case title = "title"
        case body = "description"
        case dueAt = "due_at"
        case lockedAt = "lock_at"
        case attributedText
        case quizSubmissions
        case allowedAttempts = "allowed_attempts"
    }
    
    
    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       
       // Decode required properties
       self.id = try container.decode(Int.self, forKey: .id)
       self.title = try container.decode(String.self, forKey: .title)
       self.allowedAttempts = try container.decode(Int.self, forKey: .allowedAttempts)


       
       // Decode optional properties
       self.body = try container.decodeIfPresent(String.self, forKey: .body)
       self.dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
       self.lockedAt = try container.decodeIfPresent(Date.self, forKey: .lockedAt)
    
        self.submissions = try container.decodeIfPresent([QuizSubmission].self, forKey: .quizSubmissions) ?? []
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
        try container.encodeIfPresent(self.submissions, forKey: .quizSubmissions)
        try container.encodeIfPresent(self.allowedAttempts, forKey: .allowedAttempts)
    }
    
    
}



extension Quiz {
	init(
		id: Int,
		title: String,
		dueAt: Date? = nil,
		lockedAt: Date? = nil,
		allowedAttempts: Int = 1,
		attributedText: AttributedString? = nil,
		submissions: [QuizSubmission] = []
	) {
		self.id = id
		self.title = title
		self.dueAt = dueAt
		self.lockedAt = lockedAt
		self.allowedAttempts = allowedAttempts
		self.attributedText = attributedText
		self.submissions = submissions
	}
}
