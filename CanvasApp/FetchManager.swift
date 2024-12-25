//
//  FetchManager.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/19/24.
//

import Foundation
import SwiftUI

// MARK: - Array Extension for Batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, self.count)])
        }
    }
}

struct FetchManager {
    
    private let courseClient = CourseClient()
    private let userClient = UserClient()
    private let moduleClient = ModuleClient()
    private let discussionTopicClient = DiscussionTopicClient()
    private let assignmentClient = AssignmentClient()
    private let pageClient = PageClient()
    private let enrollmentClient = EnrollmentClient()
    private let groupClient = GroupClient()
    
    private var customColorsDict: UserColorCodes! = nil
    
    private let cacheManager = CacheManager()

    private let coursesCacheFile = "courses.json"
    private let userCacheFile = "user.json"
    
    @Binding private var stage: String
    @Binding private var isLoading: Bool
    
    // If you want to throttle concurrency, adjust chunkSize:
    private let chunkSize = 5

    init(stage: Binding<String>, isLoading: Binding<Bool>) {
        self._stage = stage
        self._isLoading = isLoading
    }
    
    // MARK: - Populating Users in Batches
    private func populateUsers(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }
        
        let startTime = DispatchTime.now()
        
        // Split into small chunks of 'chunkSize'
        for chunk in wrappers.chunked(into: chunkSize) {
            await withTaskGroup(of: (Int, [EnrollmentType: [User]]?).self) { group in
                for (index, wrapper) in chunk.enumerated() {
                    group.addTask {
                        do {
                            let users = try await courseClient.getUsersEnrolledInCourse(from: wrapper.course)
                            stage = "Preparing user list for course \(wrapper.course.id)"
                            return (index, users)
                        } catch {
                            print("Failed to load user list for course \(wrapper.course.id): \(error)")
                            return (index, nil)
                        }
                    }
                }
                
                // Gather results from this chunk
                var chunkResults = Array<(Int, [EnrollmentType: [User]]?)>(repeating: (0, nil), count: chunk.count)
                for await result in group {
                    chunkResults[result.0] = (result.0, result.1)
                }
                
                // Assign the results back to each course in the chunk
                for (index, users) in chunkResults {
                    if let users = users {
                        chunk[index].course.usersInCourse = users
                    }
                }
            }
        }
        
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("User execution time: \(elapsedTime)")
    }
    
    // MARK: - Populating Pages in Batches
    private func populatePages(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }

        let startTime = DispatchTime.now()

        for chunk in wrappers.chunked(into: chunkSize) {
            await withTaskGroup(of: (Int, [Page]?).self) { group in
                for (index, wrapper) in chunk.enumerated() {
                    group.addTask {
                        do {
                            let pages = try await pageClient.retrieveCoursePages(from: wrapper.course)
                            stage = "Preparing pages from course \(wrapper.course.id)"
                            return (index, pages)
                        } catch {
                            print("Failed to load pages for course \(wrapper.course.id): \(error)")
                            return (index, nil)
                        }
                    }
                }
                
                // Gather results
                var chunkResults = Array<(Int, [Page]?)>(repeating: (0, nil), count: chunk.count)
                for await result in group {
                    chunkResults[result.0] = result
                }
                
                // Assign the results
                for (index, pages) in chunkResults {
                    if let pages = pages {
                        for var page in pages {
                            page.attributedText = HTMLRenderer.makeAttributedString(
                                from: page.body ?? "No description was provided"
                            )
                            chunk[index].course.pages.append(page)
                        }
                    }
                }
            }
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Page execution time: \(elapsedTime)")
    }
    
    // MARK: - Populating Modules in Batches
    private func populateModules(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }

        let startTime = DispatchTime.now()

        for chunk in wrappers.chunked(into: chunkSize) {
            await withTaskGroup(of: (Int, [Module]?).self) { group in
                for (index, wrapper) in chunk.enumerated() {
                    group.addTask {
                        do {
                            var modules = try await moduleClient.getModules(from: wrapper.course)
                            // Link module items to pages
                            modules = try await moduleClient.linkModuleItemsToPages(
                                from: wrapper.course,
                                fromModules: modules
                            )
                            stage = "Preparing modules for \(wrapper.course.id)"
                            return (index, modules)
                        } catch {
                            print("Failed to load modules for course \(wrapper.course.id): \(error)")
                            return (index, nil)
                        }
                    }
                }
                
                // Gather results
                var chunkResults = Array<(Int, [Module]?)>(repeating: (0, nil), count: chunk.count)
                for await result in group {
                    chunkResults[result.0] = result
                }
                
                // Assign the results
                for (index, modules) in chunkResults {
                    if let modules = modules {
                        chunk[index].course.modules = modules
                    }
                }
            }
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Module execution time: \(elapsedTime)")
    }
    
    // MARK: - Populating Announcements in Batches
    private func populateAnnouncements(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }

        let startTime = DispatchTime.now()

        for chunk in wrappers.chunked(into: chunkSize) {
            await withTaskGroup(of: (Int, [DiscussionTopic]?).self) { group in
                for (index, wrapper) in chunk.enumerated() {
                    group.addTask {
                        do {
                            let announcements = try await discussionTopicClient.getDiscussionTopicsFromCourse(
                                from: wrapper.course,
                                getAnnouncements: true
                            )
                            stage = "Preparing announcements for course \(wrapper.course.id)"
                            return (index, announcements)
                        } catch {
                            print("Failed to load announcements for course \(wrapper.course.id): \(error)")
                            return (index, nil)
                        }
                    }
                }
                
                // Gather results
                var chunkResults = Array<(Int, [DiscussionTopic]?)>(repeating: (0, nil), count: chunk.count)
                for await result in group {
                    chunkResults[result.0] = result
                }
                
                // Assign the results
                for (index, announcements) in chunkResults {
                    if var announcements = announcements {
                        for i in announcements.indices {
                            announcements[i].attributedText = HTMLRenderer.makeAttributedString(
                                from: announcements[i].body ?? "No description was provided"
                            )
                        }
                        
                        chunk[index].course.announcements = announcements
                        chunk[index].course.sortAnnouncementsByRecency()
                    }
                }
            }
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Announcement execution time: \(elapsedTime)")
    }
    
    // MARK: - Populating Assignments in Batches
    private func populateAssignments(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }

        let startTime = DispatchTime.now()

        for chunk in wrappers.chunked(into: chunkSize) {
            await withTaskGroup(of: (Int, [Assignment]?).self) { group in
                for (index, wrapper) in chunk.enumerated() {
                    group.addTask {
                        do {
                            let assignments = try await assignmentClient.getAssignmentsFromCourse(from: wrapper.course)
                            stage = "Preparing assignments from course: \(wrapper.course.id)"
                            return (index, assignments)
                        } catch {
                            print("Failed to load assignments for course \(wrapper.course.id): \(error)")
                            return (index, nil)
                        }
                    }
                }
                
                // Gather results
                var chunkResults = Array<(Int, [Assignment]?)>(repeating: (0, nil), count: chunk.count)
                for await result in group {
                    chunkResults[result.0] = result
                }
                
                // Assign the results
                for (index, assignments) in chunkResults {
                    if var assignments = assignments {
                        for i in assignments.indices {
                            assignments[i].attributedText = HTMLRenderer.makeAttributedString(
                                from: assignments[i].body ?? "No description was provided"
                            )
                            
                            // Update linked assignments in modules
                            for moduleIndex in chunk[index].course.modules.indices {
                                guard var moduleItems = chunk[index].course.modules[moduleIndex].items else { continue }
                                
                                for itemIndex in moduleItems.indices
                                    where (moduleItems[itemIndex].type == .assignment
                                           && moduleItems[itemIndex].contentID == assignments[i].id)
                                       || (moduleItems[itemIndex].type == .quiz
                                           && moduleItems[itemIndex].contentID == assignments[i].quizID) {
                                                moduleItems[itemIndex].linkedAssignment = assignments[i]
                                                let isQuiz = (moduleItems[itemIndex].type == .quiz)
                                                moduleItems[itemIndex].linkedAssignment?.isQuiz = isQuiz
                                }
                                chunk[index].course.modules[moduleIndex].items = moduleItems
                            }
                        }
                        chunk[index].course.assignments = assignments
                        chunk[index].course.sortAssignmentsByDueDate()
                    }
                }
            }
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Assignment execution time: \(elapsedTime)")
    }
    
    private func filterGroups(temp: [CourseWrapper]) {
        guard let groups = MainUser.selfUser?.groups else {
            print("No groups available for filtering")
            return
        }
        let validCourseIDs = Set(temp.map { $0.course.id })
        
        let filteredGroups = groups.filter { group in
            if let groupID = group.courseID {
                return validCourseIDs.contains(groupID)
            }
            return false
        }
        MainUser.selfUser?.groups = filteredGroups
    }
    
    // Prepare initial course wrappers (possibly from cache)
    private func prepareInitialCourses() async -> [CourseWrapper] {
        let startTime = DispatchTime.now()

        // Attempt to load cached courses
        var courses: [Course]
        if let cachedCourses: [Course] = try? cacheManager.load(from: coursesCacheFile) {
            print("Loaded courses from cache")
            courses = cachedCourses
        } else {
            print("Fetching courses from network")
            courses = await courseClient.getCoursesByCurrentTerm() ?? []
        }

        // Prepare wrappers
        let tempCourseWrappers = courses.map { course in
            let wrappedCourse = CourseWrapper(course: course)
            wrappedCourse.course.color = MainUser.selfCourseColors?.getHexCode(courseID: course.id) ?? "#000000"
            wrappedCourse.course.syllabusAttributedString = HTMLRenderer.makeAttributedString(
                from: course.syllabusBody ?? ""
            )
            
            wrappedCourse.fieldsNeedingPopulation["users"] = wrappedCourse.course.usersInCourse.isEmpty
            wrappedCourse.fieldsNeedingPopulation["pages"] = wrappedCourse.course.pages.isEmpty
            wrappedCourse.fieldsNeedingPopulation["announcements"] = wrappedCourse.course.announcements.isEmpty
            wrappedCourse.fieldsNeedingPopulation["modules"] = wrappedCourse.course.modules.isEmpty
            wrappedCourse.fieldsNeedingPopulation["assignments"] = wrappedCourse.course.assignments.isEmpty
            
            return wrappedCourse
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Course preparation execution time: \(elapsedTime)")

        return tempCourseWrappers
    }
    
    // Prepare user (possibly from cache)
    private func prepareUser() async -> User {
        var user: User?
        if let cachedUser: User = try? cacheManager.load(from: userCacheFile) {
            print("Loaded user from cache")
            user = cachedUser
        } else {
            print("Fetching user from network")
            do {
                var networkUser = try await userClient.getSelfUser()
                networkUser.enrollments = try await userClient.getUserEnrollments(from: networkUser)
                var groups = try await groupClient.getGroupsFromSelf()
                for index in groups.indices {
                    let users = try await groupClient.getUsersFromGroup(from: groups[index])
                    groups[index].users = users
                }
                networkUser.groups = groups
                
                try cacheManager.save(networkUser, to: userCacheFile)
                user = networkUser
            } catch {
                print("Failed to fetch or save user: \(error)")
            }
        }
        return user!
    }
    
    // MARK: - Main Fetch Method Using Batches
    func fetchUserAndCourses() async {
        do {
            let startTime = DispatchTime.now()
            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileURL = cacheDirectory.appendingPathComponent("courses.json")
            print("Courses cache file is located at: \(fileURL.path)")

            // 1. Prepare user
            let user = await prepareUser()
            
            // 2. Fetch user color info
            MainUser.selfCourseColors = try await userClient.getColorInfoFromSelf()
            MainUser.selfUser = user
            
            // 3. Prepare initial courses (wrappers)
            let tempCourseWrappers = await prepareInitialCourses()
            
            // Identify which fields need population
            var wrappersNeedingPopulation: [String : [CourseWrapper]] = [
                "users": [],
                "pages": [],
                "modules": [],
                "announcements": [],
                "assignments": []
            ]
            
            for wrapper in tempCourseWrappers {
                for (field, needed) in wrapper.fieldsNeedingPopulation where needed {
                    wrappersNeedingPopulation[field]?.append(wrapper)
                }
            }

            // 4. Populate Data in Batches
            await populateUsers(wrappers: wrappersNeedingPopulation["users"] ?? [])
            await populatePages(wrappers: wrappersNeedingPopulation["pages"] ?? [])
            await populateModules(wrappers: wrappersNeedingPopulation["modules"] ?? [])
            await populateAnnouncements(wrappers: wrappersNeedingPopulation["announcements"] ?? [])
            await populateAssignments(wrappers: wrappersNeedingPopulation["assignments"] ?? [])
            
            // 5. Filter groups based on valid course IDs
            filterGroups(temp: tempCourseWrappers)
            
            // 6. Save to cache & update UI on main thread
            DispatchQueue.main.async {
                do {
                    // Save the updated courses
                    try self.cacheManager.save(tempCourseWrappers.map { $0.course }, to: self.coursesCacheFile)
                } catch {
                    print("Failed to save courses to cache: \(error)")
                }
                self.isLoading = false
                MainUser.selfCourseWrappers = tempCourseWrappers
            }
            
            let endTime = DispatchTime.now()
            let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
            let elapsedTime = Double(nanoTime) / 1_000_000_000
            print("Total execution time: \(elapsedTime)")
            
        } catch {
            print("Failed to fetch user or courses: \(error)")
        }
    }
}
