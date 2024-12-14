//
//  EnrollmentClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/12/24.
//

import Foundation

struct EnrollmentClient {
    func getCourseEnrollmentsForUser(from user: User) async throws -> [Enrollment] {
        let userID = user.id!
        
        guard let url = URL(string: "\(baseURL)/users/\(String(userID))/enrollments?per_page=400") else {
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
                return try decoder.decode([Enrollment].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
        
        
    }


}


//func getEnrollmentsForCourse(from course: Course) async throws -> [Enrollment] {
//    return
//}

