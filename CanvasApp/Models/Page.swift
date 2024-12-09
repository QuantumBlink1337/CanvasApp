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

struct Page: Decodable, Identifiable, PageRepresentable {
    var attributedText: NSAttributedString? = nil
    var id: Int
    var title: String
    var body: String?
    var frontPage: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id = "page_id"
        case title = "title"
        case body = "body"
        case frontPage = "front_page"
        
    }
    
}
