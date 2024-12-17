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
    var syllabusBody: String? = nil
    var syllabusAttributedString: AttributedString = AttributedString()
    
    var id: Int
    var image_download_url: String?
    var term: Term?
    var color: String = "#000000"
    var pages: [Page] = []
    var modules: [Module] = []
    var announcements: [DiscussionTopic] = []
    var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [ : ]
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
    /// Mutating func to sort announcements into Time Period groupings. Useful for displaying Announcements in particular focused groups.
    mutating func sortAnnouncementsByRecency()  {
        var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [:]
        let timePeriods: [TimePeriod] = [.today, .yesterday, .lastWeek, .lastMonth, .previously]
        var removableAnnouncements = announcements
        for timePeriod in timePeriods {
            var announcementsInPeriod: [DiscussionTopic]
            switch timePeriod {
            case .today:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfDay = Calendar.current.startOfDay(for: Date())
                        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
//                        print("Start of day" + String(describing: startOfDay))
//                        print("end of day" + String(describing: endOfDay))
                        return postedAt >= startOfDay && postedAt < endOfDay
                    }
                    return false
                }
            case .yesterday:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!
//                        print("start of yesterday" + String(describing: startOfYesterday))
//                        print("end of yesterday" + String(describing: endOfYesterday))

                        return postedAt >= startOfYesterday && postedAt < endOfYesterday
                    }
                    return false
                }
            case .lastWeek:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
                        let startOfLastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
                        let endOfLastWeek = Calendar.current.date(byAdding: .day, value: -1, to: startOfWeek)!



                        return postedAt >= startOfLastWeek && postedAt <= endOfLastWeek
                    }
                    return false
                }
                
            case .lastMonth:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        // Get the first day of the current month
                        let firstOfCurrentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
                        // Subtract 1 month to get the first day of the previous month
                        let firstOfPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstOfCurrentMonth)!
                        // Get the last day of the previous month by subtracting 1 day from the first of the current month
                        let lastOfPreviousMonth = Calendar.current.date(byAdding: .day, value: -1, to: firstOfCurrentMonth)!
//                        print("first of prev month" + String(describing: firstOfPreviousMonth))
//                        print("last of prev month" + String(describing: lastOfPreviousMonth    ))


                        return postedAt >= firstOfPreviousMonth && postedAt <= lastOfPreviousMonth
                    }
                    return false
                }
            case .previously:
                announcementsInPeriod = removableAnnouncements
            }
            datedAnnouncements[timePeriod] = announcementsInPeriod
                removableAnnouncements.removeAll { announcement in
                    announcementsInPeriod.contains(where: {$0.id == announcement.id})
                }
            
            
        }
        self.datedAnnouncements = datedAnnouncements
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
        case syllabusBody = "syllabus_body"
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
