//
//  PageClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/28/24.
//

import Foundation

enum SpecificPage {
    case FRONT_PAGE
}

struct PageClient {
    func retrievePage(course_id: Int, page: SpecificPage) async throws -> Page {
        let endpoint: String = {
            switch page {
                case .FRONT_PAGE: return "front_page"
            }
        }()
        guard let url = URL(string: baseURL + "courses/" + String(course_id) + "/" + endpoint) else {
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
