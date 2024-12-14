//
//  Grade.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/12/24.
//

import Foundation


struct Grade : Decodable {
     
    
    var currentGrade: String?
    var currentScore: Float?
    
    enum CodingKeys : String, CodingKey {
        case currentGrade = "current_grade"
        case currentScore = "current_score"
    }
    init(currentGrade: String? = nil, currentScore: Float? = nil) {
       self.currentGrade = currentGrade
       self.currentScore = currentScore
   }
    
}
