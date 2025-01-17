

import Foundation
// https://canvas.instructure.com/doc/api/assignments.html#method.assignments_api.index

enum DatePriority: CaseIterable, Identifiable, Codable {
    var id: String { self.description }
    
    case dueSoon
    case upcoming
    case past
    case noDueDate
    
    var description: String {
        switch self {
        case .dueSoon:
            return "Due Soon"
        case .upcoming:
            return "Upcoming"
        case .past:
            return "Past"
        case .noDueDate:
            return "No Due Date"
        }
    }
}

enum SubmissionTypes : String, Codable {
    case discussionTopic = "discussion_topic"
    case onlineQuiz = "online_quiz"
    case onPaper = "on_paper"
    case none = "none"
    case externalTool = "external_tool"
    case onlineTextEntry = "online_text_entry"
    case onlineURL = "online_url"
    case onlineUpload = "online_upload"
    case mediaRecording = "media_recording"
    case studentAnnotation = "student_annotation"
}

struct Assignment : Assignable {

    var id: Int
    var title: String
    
    var body: String?
    var attributedText: AttributedString? = nil

    var createdAt: Date
    var updatedAt: Date
    var dueAt: Date?
    var lockedAt: Date?
    
    var courseID: Int
    var quizID: Int?

    var pointsPossible: Float?
    
    var submissions: [Submission] = []
    var submissionTypes: [SubmissionTypes]
    var currentSubmission: Submission?
    var scoreStatistic: ScoreStatistic?
    var quiz: Quiz?

    private enum CodingKeys : String, CodingKey {
        case id = "id"
        case title = "name"
        case body = "description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case dueAt = "due_at"
        case lockedAt = "lock_at"
        case courseID = "course_id"
        case quizID = "quiz_id"
        case pointsPossible = "points_possible"
        case scoreStatistic = "score_statistics"
        case currentSubmission = "submission"
        case submissionTypes = "submission_types"
        case submissions
        case attributedText
        case isQuiz = "is_quiz_assignment"
        case quiz
    }
    
    
    init(id: Int, title: String, dueAt: Date? = nil, body: String? = nil, quizID: Int? = nil, isQuiz: Bool = false, attributedText: AttributedString? = nil) {
            self.id = id
            self.title = title
            self.dueAt = dueAt
        self.createdAt = dueAt!
        self.updatedAt = dueAt!
            self.body = body
            self.quizID = quizID
            self.attributedText = attributedText
        self.courseID = id
        self.submissionTypes = []
        }
    
    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       
       // Decode required properties
       self.id = try container.decode(Int.self, forKey: .id)
       self.title = try container.decode(String.self, forKey: .title)
       self.createdAt = try container.decode(Date.self, forKey: .createdAt)
       self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
       self.courseID = try container.decode(Int.self, forKey: .courseID)
       
       // Decode optional properties
       self.body = try container.decodeIfPresent(String.self, forKey: .body)
       self.dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
       self.lockedAt = try container.decodeIfPresent(Date.self, forKey: .lockedAt)
       self.pointsPossible = try container.decodeIfPresent(Float.self, forKey: .pointsPossible)
       self.quizID = try container.decodeIfPresent(Int.self, forKey: .quizID)
    
    
       self.scoreStatistic = try container.decodeIfPresent(ScoreStatistic.self, forKey: .scoreStatistic)
       self.currentSubmission = try container.decodeIfPresent(Submission.self, forKey: .currentSubmission)
       self.attributedText = try container.decodeIfPresent(AttributedString.self, forKey: .attributedText)
       
       // Decode arrays with default value fallback
       self.submissionTypes = (try container.decodeIfPresent([SubmissionTypes].self, forKey: .submissionTypes)) ?? []
        self.quiz = try container.decodeIfPresent(Quiz.self, forKey: .quiz)
    
    }


    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode required properties
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(courseID, forKey: .courseID)
        
        // Encode optional properties
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(dueAt, forKey: .dueAt)
        try container.encodeIfPresent(lockedAt, forKey: .lockedAt)
        try container.encodeIfPresent(pointsPossible, forKey: .pointsPossible)
        try container.encodeIfPresent(scoreStatistic, forKey: .scoreStatistic)
        try container.encodeIfPresent(currentSubmission, forKey: .currentSubmission)
        try container.encodeIfPresent(quiz, forKey: .quiz)
        
        // Encode arrays
        try container.encode(submissionTypes, forKey: .submissionTypes)
        try container.encode(submissions, forKey: .submissions)
        
        try container.encode(attributedText, forKey: .attributedText)
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
