//
//  ModuleItem.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/5/24.
//

import Foundation
enum ModuleItemType: String, Codable {
    case file = "File"
    case page = "Page"
    case discussion = "Discussion"
    case assignment = "Assignment"
    case quiz = "Quiz"
    case subheader = "SubHeader"
    case externalURL = "ExternalUrl"
    case externalTool = "ExternalTool"
    
}

struct ModuleItem : ItemRepresentable, Codable {
    var id: Int
    var title: String
    var type: ModuleItemType
    var contentID: Int?
    
    var linkedAssignment: Assignment? = nil
    var linkedPage: Page? = nil
    
    var pageURL: String? = nil // relevant for module items that are also pages
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case contentID = "content_id"
        case pageURL = "page_url"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        let typeString = try container.decode(String.self, forKey: .type)
        type = ModuleItemType(rawValue: typeString)!
        contentID = try container.decodeIfPresent(Int.self , forKey: .contentID)
        pageURL = try container.decodeIfPresent(String.self, forKey: .pageURL)
        
       }
}
