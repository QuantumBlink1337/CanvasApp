//
//  Page.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/28/24.
//

import Foundation


struct Page: Decodable, Identifiable, PageRepresentable {
    var id: Int
    var title: String
    var body: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "page_id"
        case title = "title"
        case body = "body"
        
    }
    
}
