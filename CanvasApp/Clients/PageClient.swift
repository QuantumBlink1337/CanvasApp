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
    
    /// Returns an individual Page from a given Course.
    /// - Parameters:
    ///   - course: The Course to retrieve a Page from.
    ///   - pageURL: The String corresponding to a Page's "url" - See code for commentary
    /// - Returns: An individual Page object.
    ///
    /// This endpoint exists solely because we can't always trust the ability to query for every Page from a Course. Instructors can disable the Page
    /// feature on their Course, which means that the full Page endpoint does not work.  But ModuleItems still operate with a linked Page object.
    /// The individual query endpoint works for linking a ModuleItem with a "page_url" and grabbing an associated Page.
    func retrieveIndividualPage(from course: Course, pageURL: String) async throws -> Page {
        let urlString = "\(baseURL)courses/\(course.id)/pages/\(pageURL)"
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
            return try JSONDecoder().decode(Page.self, from: data)
        }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    
}
