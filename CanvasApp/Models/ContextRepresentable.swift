//
//  ContextRepresentable.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/2/25.
//

import Foundation


protocol ContextRepresentable: Codable, Identifiable {
    var id: Int { get set }
    var name: String? { get set }
    var color: String { get set }
    
    var datedAnnouncements: [TimePeriod : [DiscussionTopic]] { get set }

}
    
