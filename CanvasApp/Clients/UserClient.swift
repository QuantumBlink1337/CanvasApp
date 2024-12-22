//
//  UserClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/29/24.
//

import UIKit
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

struct UserClient {
    
    /// Retrieves the User object of the connected API token.
    /// Can throw an error if there is a bad URL, an invalid response, or a decoding error.
    /// - Returns: A User object.
    func getSelfUser() async throws -> User {
        guard let url = URL(string: baseURL + "users/self") else {
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
                return try JSONDecoder().decode(User.self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
        
    }
    /// Retrieves the Enrollments of a given User.
    ///  Can throw an error if there is a bad URL, an invalid response, or a decoding error.
    /// - Parameter from: the User you wish to retrieve. If the ID of the User can't be retrieved, by default it will retrieve 'self'
    /// - Returns: An array of Enrollment objects.
    func getUserEnrollments(from user: User) async throws -> [Enrollment] {
        let idString = user.id != nil ? String(user.id!) : "self"
        guard let url = URL(string: baseURL + "users/\(idString)/enrollments?per_page=400") else {
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
                return try JSONDecoder().decode([Enrollment].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    
    
    
    
    func getColorInfoFromSelf() async throws -> UserColorCodes {
        guard let url = URL(string: baseURL + "users/self/colors") else {
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
                return try JSONDecoder().decode(UserColorCodes.self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    func updateColorInfoOfCourse(courseID: Int, hexCode: String) async throws -> String{
        guard let url = URL(string: baseURL + "users/self/colors/course_"+String(courseID)) else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:url)
        let hex = hexCode.suffix(from: (hexCode.index(hexCode.startIndex, offsetBy: 1)))
        print(hex)
        request.httpMethod = "PUT"
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"hexcode\"\r\n\r\n")
        body.append("\(hex)\r\n")
        
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw NetworkError.invalidResponse
           }
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw NetworkError.badDecode
            }
            
        return responseString
    }
    func updateNicknameOfCourse(courseID: Int, nickname: String) async throws -> String{
        guard let url = URL(string: baseURL + "users/self/course_nicknames/"+String(courseID)) else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:url)
        request.httpMethod = "PUT"
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"nickname\"\r\n\r\n")
        body.append("\(nickname)\r\n")
        
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        print(courseID)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw NetworkError.invalidResponse
           }
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw NetworkError.badDecode
            }
        print(responseString)
            
        return responseString
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


