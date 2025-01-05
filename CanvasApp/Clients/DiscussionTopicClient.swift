//
//  DiscussionTopicClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/6/24.
//

import Foundation


struct DiscussionTopicClient {
    /// Retrieves Discussion Topics from a given Course.
    /// Since Announcements are a special case of Discussion Topic, this function can also do that.
    /// - Parameters:
    ///   - course: The Course you want to retrieve Discussion Topics from.
    ///   - getAnn: Whether or not you want Announcements from the course instead of regular Discussion Topics.
    ///   - loadFullAuthorData: Whether or not you want "proper" author data included with the Discussion Topic. PRECONDITION: Course users must have been retrieved prior to calling this function.
    ///
    /// - Returns: An array of DiscussionTopics.
    func getDiscussionTopicsFromCourse(from course: Course, getAnnouncements getAnn: Bool, loadFullAuthorData: Bool = true) async throws -> [DiscussionTopic] {
        let courseID = course.id
        guard let url = URL(string: "\(baseURL)courses/\(courseID)/discussion_topics\(getAnn ? "only_announcements=true" : "")") else {
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
                var discussionTopics =  try decoder.decode([DiscussionTopic].self, from: data)
                if loadFullAuthorData {
                    discussionTopics = discussionTopics.map { topic in
                        var updatedTopic = topic
                        if let authorID = topic.author?.id {
                            for (type, users) in course.people {
                                if let author = users.first(where: { $0.id == authorID }) {
                                    updatedTopic.author = author
                                    updatedTopic.authorRole = type
                                    break
                                }
                            }
                        }
                        return updatedTopic
                    }
                }
                
                return discussionTopics
            
                
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
//    func getDiscussionTopicsFromGroup(from group: Group, getAnnouncements getAnn: Bool, loadFullAuthorData: Bool = true) async throws -> [DiscussionTopic] {
//        let groupID = group.id
//        guard let url = URL(string: baseURL + "courses/" + String(groupID) + "/discussion_topics?only_announcements=" + String(getAnn)) else {
//            throw NetworkError.badURL
//        }
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .iso8601
//        var request = URLRequest(url: url)
//        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200 else {
//            throw NetworkError.invalidResponse
//            }
//        do {
//                var discussionTopics =  try decoder.decode([DiscussionTopic].self, from: data)
//                if loadFullAuthorData {
//                    discussionTopics = discussionTopics.map { topic in
//                        var updatedTopic = topic
//                        if let authorID = topic.author?.id {
//                            for (type, users) in group.users {
//                                if let author = users.first(where: { $0.id == authorID }) {
//                                    updatedTopic.author = author
//                                    updatedTopic.authorRole = type
//                                    break
//                                }
//                            }
//                        }
//                        return updatedTopic
//                    }
//                }
//                
//                return discussionTopics
//            
//                
//            }
//        catch {
//                print("Decoding error: \(error)")
//                throw NetworkError.badDecode
//            }
//    }


}




