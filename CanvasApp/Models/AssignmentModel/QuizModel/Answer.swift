//
//  Answer.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/28/25.
//

import Foundation


struct Answer : Codable, Identifiable, Equatable {
	var id: Int
	var text: String
	var html: String?
	var attributedText: AttributedString
	enum CodingKeys : String, CodingKey {
		case id
		case text
		case html
		case attributedText
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(Int.self, forKey: .id)
		self.text = try container.decode(String.self, forKey: .text)
		self.html = try container.decodeIfPresent(String.self, forKey: .html)
		self.attributedText = HTMLRenderer.makeAttributedString(from: self.html ?? "")
	}
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.text, forKey: .text)
		try container.encode(self.html, forKey: .html)
		try container.encode(self.attributedText, forKey: .attributedText)
	}
	
}
