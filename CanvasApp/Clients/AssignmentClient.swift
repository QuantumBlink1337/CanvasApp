//
//  AssignmentClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/9/24.
//

import Foundation


struct AssignmentClient {
    func getAssignmentsFromCourse(from course: Course) async throws -> [Assignment] {
        let courseID = course.id
        guard let url = URL(string: "\(baseURL)/courses/\(courseID)/assignments?per_page=400") else {
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
    
}
