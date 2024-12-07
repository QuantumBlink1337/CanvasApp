//
//  ModuleClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/5/24.
//

import Foundation



struct ModuleClient {
    func getModules(from course: Course) async throws -> [Module] {
        let courseID = course.id
        guard let url = URL(string: baseURL + "courses/"+String(courseID)+"/modules?include[]=items") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
//        print(String(data: data, encoding: .utf8) ?? "No data")
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
            }
        do {
                return try decoder.decode([Module].self, from: data)
            }
     catch DecodingError.keyNotFound(let key, let context) {
        print("Decoding error: Missing key '\(key.stringValue)' in JSON: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch DecodingError.typeMismatch(let type, let context) {
        print("Decoding error: Type mismatch for type '\(type)' in JSON: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch DecodingError.valueNotFound(let type, let context) {
        print("Decoding error: Missing value for type '\(type)' in JSON: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch DecodingError.dataCorrupted(let context) {
        print("Decoding error: Corrupted data: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch {
        print("Unknown decoding error: \(error)")
        throw NetworkError.badDecode
    }
        
    }
}
