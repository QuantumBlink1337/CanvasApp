//
//  Enrollment.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/11/24.
//

import Foundation

enum EnrollmentType: String, CaseIterable, Identifiable, Codable {
    var id: Int {rawValue.hashValue}
    
    case TeacherEnrollment = "TeacherEnrollment"
    case TaEnrollment = "TaEnrollment"
    case StudentEnrollment = "StudentEnrollment"
    case DesignerEnrollment = "DesignerEnrollment"
    case ObserverEnrollment = "ObserverEnrollment"
}

struct Enrollment: Decodable, Identifiable {
    
    
    var id: Int
    var courseID: Int
    var enrollmentState: String
    var enrollmentType: EnrollmentType
    var grade: Grade?
    
    
    
    private enum CodingKeys : String, CodingKey {
        case id
        case courseID = "course_id"
        case enrollmentState = "enrollment_state"
        case enrollmentType = "type"
        case grade = "grades"
    }
    
    init(id: Int, courseID: Int, enrollmentState: String, enrollmentType: EnrollmentType, grade: Grade? = nil) {
        self.id = id
        self.courseID = courseID
        self.enrollmentState = enrollmentState
        self.enrollmentType = enrollmentType
        self.grade = grade
    }
    
    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       id = try container.decode(Int.self, forKey: .id)
       courseID = try container.decode(Int.self, forKey: .courseID)
        enrollmentState = try container.decode(String.self, forKey: .enrollmentState)
        let enrollmentString = try container.decode(String.self, forKey: .enrollmentType)
        enrollmentType = EnrollmentType(rawValue: enrollmentString)!
        if let gradeContainer = try? container.decodeIfPresent(Grade.self, forKey: .grade) {
                    grade = gradeContainer
                } else {
                    grade = nil
                }
        
        
       }
}

