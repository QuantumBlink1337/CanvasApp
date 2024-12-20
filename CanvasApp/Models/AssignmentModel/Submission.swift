//
//  Submission.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/11/24.
//

import Foundation


struct Submission : Codable, Identifiable {
    var id: Int
    var body: String?
    var grade: String?
    var score: Float?
    var submittedAt: Date?
    var assignmentID: Int
    var userID: Int
    var graderID: Int?
    var attempt: Int?
    var late: Bool
    var missing: Bool
    
    private enum CodingKeys : String, CodingKey {
        case id
        case body
        case grade
        case score
        case submittedAt = "submitted_at"
        case assignmentID = "assignment_id"
        case userID = "user_id"
        case attempt
        case late
        case missing
        case graderID = "grader_id"
        
    }
    
}
