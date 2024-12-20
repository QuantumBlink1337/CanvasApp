//
//  CacheManager.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/20/24.
//

import Foundation


struct CacheManager {
    private let cacheDirectory: URL
    private let cacheExpiryInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    init() {
        self.cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    func save<T: Codable>(_ object: T, to fileName: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL)
    }
    
    func load<T: Codable>(from fileName: String) throws -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        
        if let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) > cacheExpiryInterval {
            return nil // Cache expired
        }
        
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func clearCache(for fileName: String) {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
