//
//  DiscussionTopicClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/6/24.
//

import Foundation


struct DiscussionTopicClient {
    func getDiscussionTopicsFromCourse(from course: Course, getAnnouncements getAnn: Bool) async throws -> [DiscussionTopic] {
        let courseID = course.id
        guard let url = URL(string: baseURL + "courses/" + String(courseID) + "/discussion_topics?only_announcements=" + String(getAnn)) else {
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
                return try decoder.decode([DiscussionTopic].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
        
        
    }

}


