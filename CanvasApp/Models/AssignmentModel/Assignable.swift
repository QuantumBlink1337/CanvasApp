//
//  Assignable.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/6/25.
//

import Foundation

protocol Assignable : Codable, Identifiable, ItemRepresentable, PageRepresentable, Hashable {
    var id: Int { get set }
    var title: String { get set }
    var body: String? { get set }
    var attributedText: AttributedString? { get set }
//    var createdAt: Date { get set }
//    var updatedAt: Date { get set }
    var dueAt: Date? { get set }
    var lockedAt: Date? { get set }
//    var courseID: Int { get set }
}
