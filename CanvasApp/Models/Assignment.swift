

import Foundation
// https://canvas.instructure.com/doc/api/assignments.html#method.assignments_api.index

enum DatePriority : Int, CaseIterable, Identifiable {
    var id: RawValue { rawValue }
    case dueSoon = 3
    case upcoming = 9
    case past = -1
}

struct Assignment : Decodable, Identifiable, ItemRepresentable, PageRepresentable {

    var id: Int
    var title: String
    
    var body: String?
    var attributedText: NSAttributedString? = nil
    
    var createdAt: Date
    var updatedAt: Date
    var dueAt: Date?
    var lockedAt: Date?
    
    var courseID: Int

    var pointsPossible: Float?

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
    }
}
