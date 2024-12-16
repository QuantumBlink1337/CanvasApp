

import Foundation
// https://canvas.instructure.com/doc/api/assignments.html#method.assignments_api.index

enum DatePriority : Int, CaseIterable, Identifiable {
    var id: RawValue { rawValue }
    case dueSoon = 3
    case upcoming = 9
    case past = -1
}

struct Assignment : Decodable, Identifiable, ItemRepresentable, PageRepresentable, Hashable {

    var id: Int
    var title: String
    
    var body: String?
    var attributedText: AttributedString? = nil
    
    var createdAt: Date
    var updatedAt: Date
    var dueAt: Date?
    var lockedAt: Date?
    
    var courseID: Int

    var pointsPossible: Float?
    
    
    var submissions: [Submission] = []
    var currentSubmission: Submission?
    var scoreStatistic: ScoreStatistic?

    private enum CodingKeys : String, CodingKey {
        case id = "id"
        case title = "name"
        case body = "description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case dueAt = "due_at"
        case lockedAt = "lock_at"
        case courseID = "course_id"
        case pointsPossible = "points_possible"
        case scoreStatistic = "score_statistics"
        case currentSubmission = "submission"
    }
    
    
    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt && lhs.courseID == rhs.courseID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(courseID)
    }
}
