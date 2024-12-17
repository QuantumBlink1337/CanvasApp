//
//  PageClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/28/24.
//

import Foundation



struct PageClient {
    func retrieveCoursePages(from course: Course) async throws -> [Page] {
        let courseID = course.id
//        let params = [URLQueryItem(name: "include[]", value: "body")]
//        guard var urlComponents = URLComponents(string: (baseURL + "courses/" + String(courseID)+"/pages?")) else {
//            throw NetworkError.badURL
//        }
//        urlComponents.queryItems = params
//        let url = urlComponents.url!
        let urlString = "\(baseURL)courses/\(courseID)/pages?include[]=body"
        guard let url = URL(string: urlString) else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        do {
            return try JSONDecoder().decode([Page].self, from: data)
        }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
              
    }
}
