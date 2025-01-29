//
//  QuizSubmission.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/19/25.
//

import Foundation

enum WorkflowState: String, CaseIterable, Hashable, Codable {
    var id: Int {rawValue.hashValue}
    case Untaken = "untaken"
    case PendingReview = "pending_review"
    case Complete = "complete"
    case SettingsOnly = "settings_only"
    case Preview = "preview"
}

struct QuizSubmission : Submittable {
    var id: Int
    
    var userID: Int
    
    var assignableID: Int
    
    var score: Float?
    
    var attempt: Int?
    
    var workflowState: WorkflowState
	
	var keptScore: Float? // each quiz submission stores whatever the highest quiz result was
	
	var validationToken: String? // if the submission was created via the app then we get a validation token to use in processing quiz taking data
	
	var isKept: Bool {
		keptScore == score
	}
    
    private enum CodingKeys : String, CodingKey {
        case id
        case userID = "user_id"
        case assignableID = "quiz_id"
        case score
        case attempt
        case workflowState = "workflow_state"
		case keptScore = "kept_score"
		case validationToken = "validation_token"
    }
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.userID = try container.decode(Int.self, forKey: .userID)
        self.assignableID = try container.decode(Int.self, forKey: .assignableID)
        self.score = try container.decodeIfPresent(Float.self, forKey: .score)
        self.attempt = try container.decodeIfPresent(Int.self, forKey: .attempt)
        let workflowState = try container.decode(String.self, forKey: .workflowState)
        self.workflowState = WorkflowState(rawValue: workflowState)! // i'd rather nuke program execution if somehow this fails
		self.keptScore = try container.decodeIfPresent(Float.self, forKey: .keptScore)
		
		self.validationToken = try container.decodeIfPresent(String.self, forKey: .validationToken)
    }
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.userID, forKey: .userID)
		try container.encode(self.assignableID, forKey: .assignableID)
		try container.encodeIfPresent(self.score, forKey: .score)
		try container.encodeIfPresent(self.attempt, forKey: .attempt)
		try container.encode(self.workflowState, forKey: .workflowState)
		try container.encode(self.keptScore, forKey: .keptScore)
	}
    
}
