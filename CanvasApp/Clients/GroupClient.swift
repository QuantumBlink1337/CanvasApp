//
//  GroupClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/23/24.
//

import Foundation

struct GroupClient {
    
    func getUsersFromGroup(from group: Group) async throws -> [User] {
        let groupID = group.id
        guard let url = URL(string: "\(baseURL)groups/\(groupID)/users?per_page=\(group.membersCount)") else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Bad response getting users from group")
            return []
//            throw NetworkError.invalidResponse
        }
        do {
                return try JSONDecoder().decode([User].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    func getDiscussionTopicsFromGroup(from group: Group, getAnnouncements: Bool = true) async throws -> [DiscussionTopic] {
        let groupID = group.id
        guard let url = URL(string: "\(baseURL)groups/\(groupID)/discussion_topics?only_announcements=\(getAnnouncements)") else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Bad response getting discussion topics from group")
            return []
//            throw NetworkError.invalidResponse
        }
        do {
                return try decoder.decode([DiscussionTopic].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    
    func getGroupsFromSelf() async throws -> [Group] {
        guard let url = URL(string: baseURL + "users/self/groups?per_page=100") else {
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
                return try JSONDecoder().decode([Group].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }

    }

    
    
}
