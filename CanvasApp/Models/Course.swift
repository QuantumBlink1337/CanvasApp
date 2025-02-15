//
//  Course.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/27/24.
//

import Foundation
import SwiftUI

class CourseWrapper: ObservableObject, Identifiable, Hashable {
    static func == (lhs: CourseWrapper, rhs: CourseWrapper) -> Bool {
        return lhs.id == rhs.id
    }
        // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var course: Course
    init(course: Course) {
        self.course = course
    }
    var fieldsNeedingPopulation: [String : Bool] = [ : ]

}


struct Course: ContextRepresentable {
    
    var people: [EnrollmentType : [User]] = [ : ]
    
    var name: String?
    var courseCode: String
    var syllabusBody: String? = nil
    var syllabusAttributedString: AttributedString = AttributedString()
    
    var totalStudents: Int = 0
    
    var id: Int
    var image_download_url: String?
    var term: Term?
    var color: String = "#000000"
    var pages: [Page] = []
    var modules: [Module] = []
    var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [ : ]
    var assignments: [Assignment] = []
    var discussionTopics: [CommentState : [DiscussionTopic]] = [ : ]
    var datedAssignments: [DatePriority : [Assignment]]? = nil
        
    
    /*
        For convenience, a computed property linking to a possible front page
     */
    var frontPage: Page? {
        let possibleFront = pages.filter{$0.frontPage}
        if !(possibleFront).isEmpty {
            return possibleFront[0]
        }
        else {
            return nil
        }
    }
    private enum CodingKeys: String, CodingKey {
          case name, id, courseCode = "course_code", syllabusBody = "syllabus_body", totalStudents = "total_students", image_download_url, term, color, pages, modules, announcements, datedAnnouncements, assignments, datedAssignments, people, discussionTopics
      }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.courseCode = try container.decode(String.self, forKey: .courseCode)
            self.syllabusBody = try container.decodeIfPresent(String.self, forKey: .syllabusBody)
            self.totalStudents = try container.decode(Int.self, forKey: .totalStudents)
            self.id = try container.decode(Int.self, forKey: .id)
            self.image_download_url = try container.decodeIfPresent(String.self, forKey: .image_download_url)
            self.term = try container.decodeIfPresent(Term.self, forKey: .term)
            self.pages = try container.decodeIfPresent([Page].self, forKey: .pages) ?? []
            self.modules = try container.decodeIfPresent([Module].self, forKey: .modules) ?? []
            self.datedAnnouncements = try container.decodeIfPresent([TimePeriod: [DiscussionTopic]].self, forKey: .datedAnnouncements) ?? [ : ]
            self.assignments = try container.decodeIfPresent([Assignment].self, forKey: .assignments) ?? []
            self.datedAssignments = try container.decodeIfPresent([DatePriority: [Assignment]].self, forKey: .datedAssignments) ?? [ : ]
            self.people = try container.decodeIfPresent([EnrollmentType: [User]].self, forKey: .people) ?? [ : ]
        self.discussionTopics = try container.decodeIfPresent([CommentState : [DiscussionTopic]] .self, forKey: .discussionTopics) ?? [:]
        }
    
    func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encodeIfPresent(name, forKey: .name)
         try container.encode(courseCode, forKey: .courseCode)
         try container.encodeIfPresent(syllabusBody, forKey: .syllabusBody)
         try container.encode(totalStudents, forKey: .totalStudents)
         try container.encode(id, forKey: .id)
         try container.encodeIfPresent(image_download_url, forKey: .image_download_url)
         try container.encodeIfPresent(term, forKey: .term)
         try container.encode(color, forKey: .color)
         try container.encode(pages, forKey: .pages)
         try container.encode(modules, forKey: .modules)
         try container.encode(datedAnnouncements, forKey: .datedAnnouncements)
         try container.encode(assignments, forKey: .assignments)
         try container.encodeIfPresent(datedAssignments, forKey: .datedAssignments)
         try container.encode(people, forKey: .people)
         try container.encode(discussionTopics, forKey: .discussionTopics)
     }
    
   

    // GPT generated initalizers for use in testing Previews
    
    init(
            name: String?,
            courseCode: String,
            id: Int,
            color: String,
            assignments: [Assignment],
            datedAssignments: [DatePriority: [Assignment]],
            enrollment: Enrollment?
        ) {
            self.name = name
            self.courseCode = courseCode
            self.id = id
            self.color = color
            self.assignments = assignments
            self.datedAssignments = datedAssignments
        }
    
    
    
    init(name: String? = nil, courseCode: String, id: Int, image_download_url: String? = nil, term: Term? = nil, color: String) {
        self.name = name
        self.courseCode = courseCode
        self.id = id
        self.image_download_url = image_download_url
        self.term = term
        self.color = color
    }
    init(
            name: String?,
            courseCode: String,
            id: Int,
            color: String,
            assignments: [Assignment],
            datedAssignments: [DatePriority: [Assignment]]? = nil
        ) {
            self.name = name
            self.courseCode = courseCode
            self.id = id
            self.color = color
            self.assignments = assignments
            self.datedAssignments = datedAssignments
        }



          
        


    }
   
    

struct Term: Codable {
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
