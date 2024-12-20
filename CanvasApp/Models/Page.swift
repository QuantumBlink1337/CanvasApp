//
//  Page.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/28/24.
//

import Foundation
enum SpecificPage {
    case FRONT_PAGE
}

struct Page: Codable, Identifiable, PageRepresentable {
    var attributedText: AttributedString? = nil
    var id: Int
    var title: String
    var body: String?
    var frontPage: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id = "page_id"
        case title = "title"
        case body = "body"
        case frontPage = "front_page"
        case attributedText
        
        
    }
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
        self.frontPage = try container.decode(Bool.self, forKey: .frontPage)
        self.attributedText = try container.decodeIfPresent(AttributedString.self, forKey: .attributedText)
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encodeIfPresent(self.body, forKey: .body)
        try container.encode(self.frontPage, forKey: .frontPage)
        try container.encodeIfPresent(self.attributedText, forKey: .attributedText)
    }
    
    
    
}
