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
    var datedAssignments: [DatePriority : [Assignment]]? = nil
    var enrollment: Enrollment? = nil
    
    
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
    /*
        Prepares a secondary Assignments grouping in the form of a Dictionary with prioritized assignments.
        Useful for displaying initial Assignment grouping or on the main status page.
     */
    mutating func sortAssignmentsByDueDate() {
        var datedAssignments: [DatePriority : [Assignment]] = [ : ]
        var removableAssignments = self.assignments
        for datePriority in DatePriority.allCases {
            var assignmentsInPeriod: [Assignment]
            switch datePriority {
            case .dueSoon:
                assignmentsInPeriod = removableAssignments.filter {
                    assignment in
                    if let dueAt = assignment.dueAt {
                        let today = Date()
                        let daysFromNow = Calendar.current.date(byAdding: .day, value: datePriority.rawValue, to: today)!
                        return dueAt >= today && dueAt <= daysFromNow
                    }
                    return false
    
                }
            case .upcoming:
                assignmentsInPeriod = removableAssignments.filter {
                    assignment in
                    if let dueAt = assignment.dueAt {
                        let today = Date()
                        let daysFromNow = Calendar.current.date(byAdding: .day, value: datePriority.rawValue, to: today)!
                        return dueAt >= today && dueAt <= daysFromNow
                    }
                    return false
    
                }
            case .past:
                assignmentsInPeriod = removableAssignments
            }
            datedAssignments[datePriority] = assignmentsInPeriod
            removableAssignments.removeAll {
                assignment in assignmentsInPeriod.contains(where: {$0.id == assignment.id})
            }
        }
        datedAssignments[.past]?.sort {first,second in
            if let firstDate = first.dueAt, let secondDate = second.dueAt {
                    return firstDate > secondDate // Sort by the soonest date first
                } else if first.dueAt == nil && second.dueAt != nil {
                    return false // Assignments without a due date go to the bottom
                } else if first.dueAt != nil && second.dueAt == nil {
                    return true // Assignments without a due date go to the bottom
                } else {
                    return false // Both are nil, no change in order
                }        }
        
        
        self.datedAssignments = datedAssignments
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
            self.enrollment = enrollment
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
