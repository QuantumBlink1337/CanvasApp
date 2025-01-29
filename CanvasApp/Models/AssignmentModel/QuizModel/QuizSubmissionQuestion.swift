//
//  QuizSubmissionQuestion.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/28/25.
//

import Foundation

enum QuizQuestionTypes : String, CaseIterable, Hashable, Codable{
	case CalculatedQuestion = "calculated_question"
	case EssayQuestion = "essay_question"
	case FileUploadQuestion = "file_upload_question"
	case FillInMultipleBlanksQuestion = "fill_in_multiple_blanks_question"
	case MatchingQuestion = "matching_question"
	case MultipleAnswersQuestion = "multiple_answers_question"
	case MultipleChoiceQuestion = "multiple_choice_question"
	case MultipleDropdownsQuestion = "multiple_dropdowns_question"
	case NumericalQuestion = "numerical_question"
	case ShortAnswerQuestion = "short_answer_question"
	case TextOnlyQuestion = "text_only_question"
	case TrueFalseQuestion = "true_false_question"
}




struct QuizSubmissionQuestion : Codable, Identifiable, Equatable {
	let id: Int
	let quizID: Int
	let quizGroupID: Int?
	let assessmentQuestionID: Int
	let position: Int
	let questionName: String
	let questionType: QuizQuestionTypes
	let questionText: String
	let attributedText: AttributedString
	let answers: [Answer]
	let flagged: Bool
	
	enum CodingKeys: String, CodingKey {
		case id
		case quizID = "quiz_id"
		case quizGroupID = "quiz_group_id"
		case assessmentQuestionID = "assessment_question_id"
		case position
		case questionName = "question_name"
		case questionType = "question_type"
		case questionText = "question_text"
		case attributedText
		case answers
		case flagged
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(Int.self, forKey: .id)
		self.quizID = try container.decode(Int.self, forKey: .quizID)
		self.quizGroupID = try container.decodeIfPresent(Int.self, forKey: .quizGroupID)
		self.assessmentQuestionID = try container.decode(Int.self, forKey: .assessmentQuestionID)
		self.position = try container.decode(Int.self, forKey: .position)
		self.questionName = try container.decode(String.self, forKey: .questionName)
		let type = try container.decode(String.self, forKey: .questionType)
		self.questionType = QuizQuestionTypes(rawValue: type)!
		self.questionText = try container.decode(String.self, forKey: .questionText)
		
		if let attributedTextHTML = try container.decodeIfPresent(String.self, forKey: .attributedText) {
			self.attributedText = HTMLRenderer.makeAttributedString(from: attributedTextHTML)
		} else {
			// Derive `attributedText` from `questionText` if not present in JSON
			self.attributedText = HTMLRenderer.makeAttributedString(from: self.questionText)
		}
		self.answers = try container.decode([Answer].self, forKey: .answers)
		self.flagged = try container.decode(Bool.self, forKey: .flagged)
	}
	
	
}
