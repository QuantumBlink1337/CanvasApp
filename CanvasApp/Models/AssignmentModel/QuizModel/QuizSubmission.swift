//
//  QuizSubmission.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/19/25.
//

import Foundation

struct QuizSubmission : Submittable {
    var id: Int
    
    var userID: Int
    
    var assignableID: Int
    
    var score: Float?
    
    var attempt: Int?
    
    private enum CodingKeys : String, CodingKey {
        case id
        case userID = "user_id"
        case assignableID = "quiz_id"
        case score
        case attempt
    }
    
}
