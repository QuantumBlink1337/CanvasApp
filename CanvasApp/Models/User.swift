//
//  User.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/29/24.
//

import Foundation


struct User: Codable, Identifiable {
    var id: Int?
    var firstName: String?
    var lastName: String?
    var name: String?
    var fullName: String {
        return firstName! + " " + lastName!
    }
    var displayName: String?
    var pronouns: String?
    var avatarURL: String?
    
    var enrollments: [Enrollment] = []
    var groups: [Group] = []
    
    
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case pronouns
        case avatarURL = "avatar_url"
        case name = "name"
        case enrollments
        case groups
    }

        init(
            id: Int? = nil,
            firstName: String? = nil,
            lastName: String? = nil,
            name: String? = nil,
            displayName: String? = nil,
            pronouns: String? = nil,
            avatarURL: String? = nil,
            enrollments: [Enrollment] = [],
            groups: [Group] = []
        ) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.name = name
            self.displayName = displayName
            self.pronouns = pronouns
            self.avatarURL = avatarURL
            self.enrollments = enrollments
            self.groups = groups
        }

    
    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.pronouns = try container.decodeIfPresent(String.self, forKey: .pronouns)
        self.avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.enrollments = try container.decodeIfPresent([Enrollment].self, forKey: .enrollments) ?? []
        self.groups = try container.decodeIfPresent([Group].self, forKey: .groups) ?? []
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.id, forKey: .id)
        try container.encodeIfPresent(self.firstName, forKey: .firstName)
        try container.encodeIfPresent(self.lastName, forKey: .lastName)
        try container.encodeIfPresent(self.displayName, forKey: .displayName)
        try container.encodeIfPresent(self.pronouns, forKey: .pronouns)
        try container.encodeIfPresent(self.avatarURL    , forKey: .avatarURL)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encode(self.enrollments, forKey: .enrollments)
        try container.encode(self.groups, forKey: .groups)
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
