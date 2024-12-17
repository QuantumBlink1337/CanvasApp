//
//  Module.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/5/24.
//

import Foundation


struct Module : Decodable, Identifiable {
    var id: Int
    var position: Int
    var name: String
    var itemsCount: Int
    var itemsURLString: String
    var published: Bool?
    var items: [ModuleItem]?
    
    
    private enum CodingKeys: String, CodingKey {
        case id 
        case position
        case name
        case itemsCount = "items_count"
        case itemsURLString = "items_url"
        case published
        case items = "items"
    }
}
