//
//  AssignmentClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/9/24.
//

import Foundation
struct SubmissionResponse: Decodable {
    let submissions: [Submission]
    
    // A custom initializer to decode either a single object or an array
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let singleSubmission = try? container.decode(Submission.self) {
            self.submissions = [singleSubmission] // If it's a single submission, wrap it in an array
        } else {
            self.submissions = try container.decode([Submission].self) // Otherwise, decode an array
        }
    }
}



struct AssignmentClient {
    func getAssignmentsFromCourse(from course: Course) async throws -> [Assignment] {
        let courseID = course.id
        guard let url = URL(string: "\(baseURL)/courses/\(courseID)/assignments?per_page=400&include[]=score_statistics&include[]=submission") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
            }
        do {
                return try decoder.decode([Assignment].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    func getSubmissionForAssignment(from assignment: Assignment) async throws -> [Submission] {
        guard let url = URL(string: "\(baseURL)/courses/\(assignment.courseID)/assignments/\(assignment.id)/submissions/self") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            // Decode the response into a SubmissionResponse
            let submissionResponse = try decoder.decode(SubmissionResponse.self, from: data)
            return submissionResponse.submissions
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.badDecode
        }
    }
    func getQuizFromAssignment(from assignment: Assignment) async throws -> Quiz {
        guard let url = URL(string: "\(baseURL)/courses/\(assignment.courseID)/quizzes/\(assignment.quizID ?? 0)") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
            }
        do {
                return try decoder.decode(Quiz.self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    func getQuizSubmissions(from assignment: Assignment) async throws -> [QuizSubmission] {
        if assignment.quizID == nil {
            print("Requested Quiz Submissions does not have a quiz ID from which to search")
            throw DataError.missingData
        }
        guard let url = URL(string: "\(baseURL)/courses/\(assignment.courseID)/quizzes/\(assignment.quizID ?? 0)/submissions") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
            }
        do {
            let dict: [String : [QuizSubmission]] = try decoder.decode([String : [QuizSubmission]].self, from: data)
            return dict.values.first ?? []
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
	
	/// Create the Quiz Submission (start a quiz taking session)
	/// Start taking a Quiz by creating a QuizSubmission which you can use to answer questions and submit your answers.
	/// This is a POST endpoint
	/// https://canvas.instructure.com/doc/api/quiz_submissions.html#method.quizzes/quiz_submissions_api.create
	/// This endpoint will return a new QuizSubmission object when it's successful.
	///
	/// - Parameter assignment: An Assignment object. It needs to have a valid Quiz object associated with it.
	func createQuizSubmission(from assignment: Assignment) async throws -> QuizSubmission {
		if assignment.quiz == nil {
			print("The assignment given does not have a valid Quiz associated with it")
			throw DataError.missingData
		}
		guard let url = URL(string: "\(baseURL)/courses/\(assignment.courseID)/quizzes/\(assignment.quizID!)/submissions") else {
			throw NetworkError.badURL
		}
		var request = URLRequest(url:url)
		request.httpMethod = "POST"
		request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
		
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let (data, response) = try await URLSession.shared.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse,
			  httpResponse.statusCode == 200 
		else {
			throw NetworkError.invalidResponse
		}
		do {
			let quizSubmission = (try decoder.decode([String : [QuizSubmission]].self, from: data)).values.first?.first
			return quizSubmission!
		}
		catch {
			print("Decoding error: \(error)")
			throw NetworkError.badDecode
		}
	}
	func retrieveQuizSubmissionQuestions(from quizSubmission: QuizSubmission) async throws -> [QuizSubmissionQuestion] {
		if quizSubmission.workflowState != WorkflowState.Untaken {
			print("The quiz submission given isn't untaken yet.")
			throw DataError.missingData
		}
		guard let url = URL(string: "\(baseURL)/quiz_submissions/\(quizSubmission.id)/questions") else {
			throw NetworkError.badURL
		}
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		var request = URLRequest(url: url)
		request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse,
			  httpResponse.statusCode == 200
		else {
			throw NetworkError.invalidResponse
		}
		do {
			let questions = (try decoder.decode([String : [QuizSubmissionQuestion]].self, from: data)).values.first ?? []
			return questions
		}
		catch {
			print("Decoding error: \(error)")
			throw NetworkError.badDecode
		}
		
		
	}
//	func answerQuizQuestion(from quiz: Quiz, quizQuestion: QuizSubmissionQuestion) async throws {
//		
//	}
    
}


/// Represents different formats an answer can take when submitting to the API
enum AnswerValue: Codable {
	case text(String)            // Essay, Short Answer
	case number(Double)          // Numerical Questions
	case multipleChoice(Int)     // Multiple Choice (Single Answer)
	case multipleAnswers([Int])  // Multiple Answers (Array of Answer IDs)
	case fileUpload(URL)         // File Upload (URL)
	case matchingPairs([MatchingPair]) // Matching Question (Array of Answer-Match ID pairs)
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		// Try decoding in different formats based on possible answer types
		if let number = try? container.decode(Double.self) {
			self = .number(number)
		} else if let text = try? container.decode(String.self) {
			self = .text(text)
		} else if let multipleChoiceID = try? container.decode(Int.self) {
			self = .multipleChoice(multipleChoiceID)
		} else if let multipleAnswersIDs = try? container.decode([Int].self) {
			self = .multipleAnswers(multipleAnswersIDs)
		} else if let matchingPairs = try? container.decode([MatchingPair].self) {
			self = .matchingPairs(matchingPairs)
		} else if let fileURL = try? container.decode(URL.self) {
			self = .fileUpload(fileURL)
		} else {
			throw DecodingError.typeMismatch(
				AnswerValue.self,
				DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported answer type")
			)
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
			case .text(let value):
				try container.encode(value)
			case .number(let value):
				try container.encode(value)
			case .multipleChoice(let value):
				try container.encode(value)
			case .multipleAnswers(let values):
				try container.encode(values)
			case .matchingPairs(let pairs):
				try container.encode(pairs)
			case .fileUpload(let url):
				try container.encode(url.absoluteString)
		}
	}
}
/// Represents a matching pair for matching questions
struct MatchingPair: Codable {
	let answerID: Int
	let matchID: Int
	
	enum CodingKeys: String, CodingKey {
		case answerID = "answer_id"
		case matchID = "match_id"
	}
}
struct SubmittedAnswer: Codable {
	var id: Int
	var answer: AnswerValue
	
	enum CodingKeys: String, CodingKey {
		case id
		case answer
	}
}

struct QuizSubmissionRequest: Codable {
	var attempt: Int
	var validationToken: String
	var accessCode: String? // Nullable
	var quizQuestions: [SubmittedAnswer]
	
	enum CodingKeys: String, CodingKey {
		case attempt
		case validationToken = "validation_token"
		case accessCode = "access_code"
		case quizQuestions = "quiz_questions"
	}
}

