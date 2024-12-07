//
//  User.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/29/24.
//

import Foundation


struct User: Codable, Identifiable {
    var id: Int
    var firstName: String?
    var lastName: String?
    var fullName: String {
        return firstName! + " " + lastName!
    }
    var displayName: String?
    var pronouns: String?
    var avatarURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case pronouns
        case avatarURL = "avatar_image_url"
    }
}
struct UserColorCodes: Codable {
    var customColors: [String: String]
    
    enum CodingKeys: String, CodingKey  {
        case customColors =  "custom_colors"
    }
    func getHexCode(courseID: Int) -> String? {
        let assetCode = "course_" + String(courseID)
        guard let hex = customColors[assetCode] else { return nil }
        return hex
    }
    mutating func updateColorCodes(courseID: Int, hexCode: String) {
        let assetCode = "course_" + String(courseID)
        customColors.updateValue(hexCode, forKey: assetCode)

    }
    
    
}
