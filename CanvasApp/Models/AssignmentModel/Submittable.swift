//
//  Submittable.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/19/25.
//

import Foundation

protocol Submittable :  Codable, Identifiable {
    var id: Int {get set} // ID of the object
    var userID: Int { get set } // User ID that the submission belongs to
    var assignableID: Int {get set}// ID of the associated Assignable instance (quiz, assignment)
    var score: Float? {get set} // Score of the submission (this might be a casted int for quizzes)
    var attempt: Int? {get set} // How many times the assignable had something submitted
    
    
    

}
