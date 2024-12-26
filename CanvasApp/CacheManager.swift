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
    
    // MARK: - Per-Course Directory Management
    private func courseDirectory(forCourseID courseID: Int) -> URL {
        let dir = cacheDirectory
            .appendingPathComponent("courses", isDirectory: true)
            .appendingPathComponent("\(courseID)", isDirectory: true)
        
        // Create the folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Save/Load Course Data
    func saveCourseData<T: Codable>(_ object: T, courseID: Int, fileName: String) throws {
        let directory = courseDirectory(forCourseID: courseID)
        let fileURL = directory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL)
    }
    
    func loadCourseData<T: Codable>(courseID: Int, fileName: String) throws -> T? {
        let directory = courseDirectory(forCourseID: courseID)
        let fileURL = directory.appendingPathComponent(fileName)
        
        // If no file, nothing to load
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check expiration
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) > cacheExpiryInterval {
            // Cache expired
            return nil
        }
        
        // Decode
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // Inside CacheManager.swift

    // MARK: - Save/Load Enrollment Data
    func saveEnrollmentData(_ data: [EnrollmentType: [User]], courseID: Int) throws {
        try saveCourseData(data, courseID: courseID, fileName: "enrollments.json")
    }

    func loadEnrollmentData(courseID: Int) throws -> [EnrollmentType: [User]]? {
        return try loadCourseData(courseID: courseID, fileName: "enrollments.json")
    }

    
    
    // MARK: - Clear Course Data
    func clearCourseData(courseID: Int, fileName: String) {
        let directory = courseDirectory(forCourseID: courseID)
        let fileURL = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Legacy (or Shared) User Cache
    func save<T: Codable>(_ object: T, to fileName: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL)
    }
    
    func load<T: Codable>(from fileName: String) throws -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) > cacheExpiryInterval {
            // Cache expired
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func clearCache(for fileName: String) {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
