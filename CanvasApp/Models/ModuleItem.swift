//
//  ModuleItem.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/5/24.
//

import Foundation
enum ModuleItemType: String {
    case file = "File"
    case page = "Page"
    case discussion = "Discussion"
    case assignment = "Assignment"
    case quiz = "Quiz"
    case subheader = "SubHeader"
    case externalURL = "ExternalUrl"
    case externalTool = "ExternalTool"
    
}

struct ModuleItem : ItemRepresentable, Decodable {
    var id: Int
    var title: String
    var type: String
    
   // var contentID: Int?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
    //    case contentID = "content_id"
    }
}
