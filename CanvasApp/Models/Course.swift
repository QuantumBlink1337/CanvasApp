//
//  Course.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/27/24.
//

import Foundation
import SwiftUI

class CourseWrapper: ObservableObject, Identifiable {
    @Published var course: Course
    init(course: Course) {
        self.course = course
    }
}


struct Course: Decodable, Encodable, Identifiable {
    var name: String?
    var courseCode: String
    var id: Int
    var image_download_url: String?
    var term: Term?
    var color: String = "#000000"
    var pages: [Page] = []
    var modules: [Module] = []
    var announcements: [DiscussionTopic] = []
    var assignments: [Assignment] = []
    
    
    var frontPage: Page? {
        let possibleFront = pages.filter{$0.frontPage}
        if !(possibleFront).isEmpty {
            return possibleFront[0]
        }
        else {
            return nil
        }
    }
    
    
    
    init(name: String? = nil, courseCode: String, id: Int, image_download_url: String? = nil, term: Term? = nil, color: String) {
        self.name = name
        self.courseCode = courseCode
        self.id = id
        self.image_download_url = image_download_url
        self.term = term
        self.color = color
    }


    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case image_download_url
        case term
        case courseCode = "course_code"
//        case color = "color"
    }
          
        


    }
   
    

struct Term: Decodable, Encodable {
    let id: Int
    let name: String
    let startAt: Date?
    let endAt: Date?
    
    init(id: Int, name: String, startAt: Date?, endAt: Date?) {
        self.id = id
        self.name = name
        self.startAt = startAt
        self.endAt = endAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case startAt = "start_at"
        case endAt = "end_at"
        
    }
}
