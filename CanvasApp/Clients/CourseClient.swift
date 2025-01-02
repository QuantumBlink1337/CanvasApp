//
//  CourseClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/27/24.
//

import Foundation




struct CourseClient {
    private func getActiveCourses() async throws -> [Course] {
        guard let url = URL(string: "\(baseURL)courses?per_page=400&enrollment_state=active&include[]=term&include[]=course_image&include[]=syllabus_body&include[]=total_students") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
            }
        do {
                return try decoder.decode([Course].self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    /*
        Calls getCourses and attempts to pick out courses within the current term (or those without terms) and returns those.
     */
    func getCoursesByCurrentTerm() async -> [Course]? {
        do {
            let rawCourses = try await getActiveCourses()
            var foundCourses: [(course: Course, isPermanent: Bool)] = []
            rawCourses.forEach { course in
                if let start = course.term?.startAt, let end = course.term?.endAt {
                    let range = start...end
                    if range.contains(Date()) {
                        foundCourses.append((course: course, isPermanent: false))
                    }
                }
                else {
                    // If the course doesn't have a Term, it's likely a permanent course.
                    foundCourses.append((course: course, isPermanent: true))
                }
                foundCourses.sort {
                    !$0.isPermanent && $1.isPermanent
                }
                
                
                
            }
            return foundCourses.map {$0.course}
            
        } catch let error {
            // Handle the error
            print("Failed to fetch courses: \(error)")
            
        }
        return nil
    }
    // Returns a string hex representation of a color associated with a Course.
    // Strangely enough, colors are associated with the User. So we will need the user ID of the user whom possesses the courses.
    func getCourseColor(courseID: Int, userID: Int) async throws-> String {
        guard let URL = URL(string: baseURL + "users/" + String(userID) + "/colors/course_"+String(courseID)) else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:URL)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        do {
                return try JSONDecoder().decode(String.self, from: data)
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
    }
    
    /// Returns the Users enrolled in a given Course, grouped by Enrollment Type.
    /// Attaches avatar URL to User.
    /// - Parameter course: A Course object.
    /// - Returns: A dictionary with Users keyed by Enrollment Type
    func getUsersEnrolledInCourse(from course: Course) async throws -> [EnrollmentType : [User]] {
        guard let URL = URL(string: baseURL + "courses/\(course.id)/search_users?per_page=600)&include[]=avatar_url&include[]=enrollments") else {
            throw NetworkError.badURL
        }
        var request = URLRequest(url:URL)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        do {
                let users = try JSONDecoder().decode([User].self, from: data)
                return Dictionary(grouping: users, by: {$0.enrollments.first!.enrollmentType})
            }
        catch {
                print("Decoding error: \(error)")
                throw NetworkError.badDecode
            }
        
        
        
        
//        for type in EnrollmentType.allCases {
//            guard let URL = URL(string: baseURL + "courses/\(course.id)/search_users?include[]=avatar_url&per_page=\(min(600, course.totalStudents))&enrollment_type[]=\(type.rawValue)") else {
//                throw NetworkError.badURL
//            }
//            var request = URLRequest(url:URL)
//            request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
//            let (data, response) = try await URLSession.shared.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse,
//                  httpResponse.statusCode == 200 else {
//                throw NetworkError.invalidResponse
//            }
//            do {
//                    let users = try JSONDecoder().decode([User].self, from: data)
//                    enrolledUsers.updateValue(users, forKey: type)
//                }
//            catch {
//                    print("Decoding error: \(error)")
//                    throw NetworkError.badDecode
//                }
//        }
//        return enrolledUsers
    
        
    }
}
