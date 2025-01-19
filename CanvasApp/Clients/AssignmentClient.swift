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

    
}
