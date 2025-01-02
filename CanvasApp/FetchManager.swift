//
//  FetchManager.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/19/24.
//

import Foundation
import SwiftUI
import os

// MARK: - Array Extension for Batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, self.count)])
        }
    }
}

/// A wrapper for parallel chunk-based fetching to reduce repetitive TaskGroup code.
func parallelFetchInChunks<Input, Output>(
    inputs: [Input],
    chunkSize: Int,
    operation: @escaping (Input) async throws -> Output
) async -> [Output?] {
    var results = Array<Output?>(repeating: nil, count: inputs.count)
    
    // We can break inputs into chunks
    for subChunk in inputs.chunked(into: chunkSize) {
        await withTaskGroup(of: (Int, Output?).self) { group in
            for input in subChunk {
                // Safe index retrieval
                guard let globalIndex = inputs.firstIndex(where: { $0 as AnyObject === input as AnyObject }) else {
                    continue
                }
                group.addTask {
                    do {
                        let output = try await operation(input)
                        return (globalIndex, output)
                    } catch {
                        print("Operation failed for index \(globalIndex): \(error)")
                        return (globalIndex, nil)
                    }
                }
            }
            // Gather results for this chunk
            for await (i, output) in group {
                results[i] = output
            }
        }
    }
    return results
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
    
    private let cacheManager = CacheManager()
    
    private let userCacheFile = "user.json"
    
    @Binding private var stage: String
    @Binding private var isLoading: Bool
    
    let fetchManagerLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FetchManager")
    
    // If you want to throttle concurrency, adjust chunkSize:
    private let chunkSize = 5

    init(stage: Binding<String>, isLoading: Binding<Bool>) {
        self._stage = stage
        self._isLoading = isLoading
    }
    

    // MARK: - Populating Users (with caching)
    private func populateUsers(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }
        let startTime = DispatchTime.now()
        
        let results = await parallelFetchInChunks(
            inputs: wrappers,
            chunkSize: chunkSize
        ) { wrapper in
            let courseID = wrapper.course.id
            fetchManagerLogger.debug("")
            
            // Attempt to load enrollments from cache
            if let cachedEnrollments: [EnrollmentType: [User]] =
                try? cacheManager.loadEnrollmentData(courseID: courseID),
               !cachedEnrollments.isEmpty {
                return cachedEnrollments
            }
            
            // Otherwise, fetch from network
            let enrollments = try await courseClient.getUsersEnrolledInCourse(from: wrapper.course)
            
            // Cache the fetched enrollments
            try? cacheManager.saveEnrollmentData(enrollments, courseID: courseID)
            return enrollments
        }
        
        // Assign results
        for (index, enrollments) in results.enumerated() {
            guard let enrollments = enrollments else { continue }
            
            // Assuming `usersInCourse` is of type `[EnrollmentType: [User]]`
            wrappers[index].course.usersInCourse = enrollments
            
            // Optionally, update UI stage or other properties
            stage = "Preparing user list for course \(wrappers[index].course.id)"
        }
        
        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        print("User execution time: \(elapsed) seconds")
    }

    
    // MARK: - Populating Pages (with caching example)
    private func populatePages(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }
        let startTime = DispatchTime.now()
        
        let results = await parallelFetchInChunks(
            inputs: wrappers,
            chunkSize: chunkSize
        ) { wrapper in
            let courseID = wrapper.course.id
            
            // 1. Try loading from cache first
            if let cachedPages: [Page] = try? cacheManager.loadCourseData(courseID: courseID, fileName: "pages.json"),
               !cachedPages.isEmpty {
                print("Loading Pages (\(courseID) from Cache)")

                // If found valid pages, return them
                return cachedPages
            }
            
            // 2. Otherwise fetch from network
            print("Loading Pages (\(courseID) from Network)")
            let pages = try await pageClient.retrieveCoursePages(from: wrapper.course)
            
            // 3. Cache them
            try? cacheManager.saveCourseData(pages, courseID: courseID, fileName: "pages.json")
            return pages
        }
        
        // Assign results
        for (index, pages) in results.enumerated() {
            guard var fetchedPages = pages else { continue }
            
            // Convert HTML => attributed
            for i in fetchedPages.indices {
                fetchedPages[i].attributedText = HTMLRenderer.makeAttributedString(
                    from: fetchedPages[i].body ?? "No description was provided"
                )
            }
            wrappers[index].course.pages = fetchedPages
            stage = "Preparing pages from course \(wrappers[index].course.id)"
        }
        
        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        print("Page execution time: \(elapsed)")
    }
    
    // MARK: - Populating Modules (with caching example)
    private func populateModules(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }
        let startTime = DispatchTime.now()

        let results = await parallelFetchInChunks(
            inputs: wrappers,
            chunkSize: chunkSize
        ) { wrapper in
            let courseID = wrapper.course.id
            
            // Try cache first
            if let cachedModules: [Module] = try? cacheManager.loadCourseData(courseID: courseID, fileName: "modules.json"),
               !cachedModules.isEmpty {
                return cachedModules
            }
            
            // Otherwise fetch from network
            var modules = try await moduleClient.getModules(from: wrapper.course)
            modules = try await moduleClient.linkModuleItemsToPages(from: wrapper.course, fromModules: modules)
            
            // Save to cache
            try? cacheManager.saveCourseData(modules, courseID: courseID, fileName: "modules.json")
            return modules
        }
        
        // Assign results
        for (index, modules) in results.enumerated() {
            guard let modules = modules else { continue }
            wrappers[index].course.modules = modules
            stage = "Preparing modules for course \(wrappers[index].course.id)"
        }

        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        print("Module execution time: \(elapsed)")
    }
    
    // MARK: - Populating Announcements
    private func populateAnnouncements(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }
        let startTime = DispatchTime.now()

        let results = await parallelFetchInChunks(
            inputs: wrappers,
            chunkSize: chunkSize
        ) { wrapper in
            let courseID = wrapper.course.id
            
            // Cache check
            if let cachedAnnouncements: [DiscussionTopic] =
                try? cacheManager.loadCourseData(courseID: courseID, fileName: "announcements.json"),
               !cachedAnnouncements.isEmpty {
                return cachedAnnouncements
            }
            
            // Fetch
            let announcements = try await discussionTopicClient.getDiscussionTopicsFromCourse(
                from: wrapper.course,
                getAnnouncements: true
            )
            // Save
            try? cacheManager.saveCourseData(announcements, courseID: courseID, fileName: "announcements.json")
            return announcements
        }
        
        // Assign
        for (index, announcements) in results.enumerated() {
            guard var items = announcements else { continue }
            for i in items.indices {
                items[i].attributedText = HTMLRenderer.makeAttributedString(
                    from: items[i].body ?? "No description was provided"
                )
            }
            wrappers[index].course.datedAnnouncements = sortAnnouncementsByRecency(from: items)
            stage = "Preparing announcements for course \(wrappers[index].course.id)"
        }

        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        print("Announcement execution time: \(elapsed)")
    }
    
    // MARK: - Populating Assignments
    private func populateAssignments(wrappers: [CourseWrapper]) async {
        guard !wrappers.isEmpty else { return }
        let startTime = DispatchTime.now()

        let results = await parallelFetchInChunks(
            inputs: wrappers,
            chunkSize: chunkSize
        ) { wrapper in
            let courseID = wrapper.course.id
            
            // Try load from cache
            if let cachedAssignments: [Assignment] =
                try? cacheManager.loadCourseData(courseID: courseID, fileName: "assignments.json"),
               !cachedAssignments.isEmpty {
                return cachedAssignments
            }
            
            // Otherwise fetch
            let assignments = try await assignmentClient.getAssignmentsFromCourse(from: wrapper.course)
            
            // Cache them
            try? cacheManager.saveCourseData(assignments, courseID: courseID, fileName: "assignments.json")
            return assignments
        }
        
        // Assign
        for (index, assignments) in results.enumerated() {
            guard var items = assignments else { continue }
            
            for i in items.indices {
                items[i].attributedText = HTMLRenderer.makeAttributedString(
                    from: items[i].body ?? "No description was provided"
                )
                
                // Update modules with linked assignment references
                // 1. Copy modules locally
                var localModules = wrappers[index].course.modules
                
                for moduleIndex in localModules.indices {
                    guard var moduleItems = localModules[moduleIndex].items else { continue }
                    
                    for itemIndex in moduleItems.indices {
                        if (moduleItems[itemIndex].type == .assignment
                            && moduleItems[itemIndex].contentID == items[i].id)
                           || (moduleItems[itemIndex].type == .quiz
                               && moduleItems[itemIndex].contentID == items[i].quizID) {
                            items[i].isQuiz = (moduleItems[itemIndex].type == .quiz)
                            moduleItems[itemIndex].linkedAssignment = items[i]
                        }
                    }
                    
                    // Assign mutated moduleItems back
                    localModules[moduleIndex].items = moduleItems
                }
                
                // 2. Write back the updated local modules array
                wrappers[index].course.modules = localModules
            }
            
            wrappers[index].course.assignments = items
            wrappers[index].course.sortAssignmentsByDueDate()
            stage = "Preparing assignments for course \(wrappers[index].course.id)"
        }

        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        print("Assignment execution time: \(elapsed)")
    }

    // Filter groups that match valid course IDs
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
    
    // MARK: - Prepare initial courses
    private func prepareInitialCourses() async -> [CourseWrapper] {
        let startTime = DispatchTime.now()

        // Attempt to load courses from somewhere (could be a top-level `courses.json` or direct from network)
        // We'll just fetch from the network for demonstration:
        let courses = await courseClient.getCoursesByCurrentTerm() ?? []
        
        // Prepare wrappers
        let tempCourseWrappers = courses.map { course in
            let wrappedCourse = CourseWrapper(course: course)
            wrappedCourse.course.color = MainUser.selfCourseColors?.getHexCode(courseID: course.id) ?? "#000000"
            wrappedCourse.course.syllabusAttributedString = HTMLRenderer.makeAttributedString(
                from: course.syllabusBody ?? ""
            )
            
            wrappedCourse.fieldsNeedingPopulation["users"] = wrappedCourse.course.usersInCourse.isEmpty
            wrappedCourse.fieldsNeedingPopulation["pages"] = wrappedCourse.course.pages.isEmpty
            wrappedCourse.fieldsNeedingPopulation["announcements"] = wrappedCourse.course.datedAnnouncements.isEmpty
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
    
    // MARK: - Prepare user
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
                
                // Fetch groups
                var groups = try await groupClient.getGroupsFromSelf()
                for index in groups.indices {
                    let users = try await groupClient.getUsersFromGroup(from: groups[index])
                    let announcements = try await groupClient.getDiscussionTopicsFromGroup(from: groups[index], getAnnouncements: true)
                    groups[index].users = users
                    groups[index].datedAnnouncements = sortAnnouncementsByRecency(from: announcements)
                }
                networkUser.groups = groups
                
                // Save user
                try cacheManager.save(networkUser, to: userCacheFile)
                user = networkUser
            } catch {
                print("Failed to fetch or save user: \(error)")
            }
        }
        return user!
    }
    
    // MARK: - Main Fetch
    func fetchUserAndCourses() async {
        do {
            let startTime = DispatchTime.now()
            
            // 1. Prepare user
            let user = await prepareUser()
            MainUser.selfUser = user
            
            // 2. Fetch user color info
            MainUser.selfCourseColors = try await userClient.getColorInfoFromSelf()
            
            // 3. Prepare initial course wrappers
            let tempCourseWrappers = await prepareInitialCourses()
            
            // Identify which fields need population
            var wrappersNeedingPopulation: [String: [CourseWrapper]] = [
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
            
            // 4. Populate Data
            await populateUsers(wrappers: wrappersNeedingPopulation["users"] ?? [])
            await populatePages(wrappers: wrappersNeedingPopulation["pages"] ?? [])
            await populateModules(wrappers: wrappersNeedingPopulation["modules"] ?? [])
            await populateAnnouncements(wrappers: wrappersNeedingPopulation["announcements"] ?? [])
            await populateAssignments(wrappers: wrappersNeedingPopulation["assignments"] ?? [])
            
            // 5. Filter groups
            filterGroups(temp: tempCourseWrappers)
            
            // 6. Mark loading complete & update global state
            DispatchQueue.main.async {
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
    
    
    
    
    
    func sortAnnouncementsByRecency(from announcements: [DiscussionTopic]) -> [TimePeriod : [DiscussionTopic]]  {
        var datedAnnouncements: [TimePeriod : [DiscussionTopic]] = [:]
        let timePeriods: [TimePeriod] = [.today, .yesterday, .lastWeek, .lastMonth, .previously]
        var removableAnnouncements = announcements
        for timePeriod in timePeriods {
            var announcementsInPeriod: [DiscussionTopic]
            switch timePeriod {
            case .today:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfDay = Calendar.current.startOfDay(for: Date())
                        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
//                        print("Start of day" + String(describing: startOfDay))
//                        print("end of day" + String(describing: endOfDay))
                        return postedAt >= startOfDay && postedAt < endOfDay
                    }
                    return false
                }
            case .yesterday:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!
//                        print("start of yesterday" + String(describing: startOfYesterday))
//                        print("end of yesterday" + String(describing: endOfYesterday))

                        return postedAt >= startOfYesterday && postedAt < endOfYesterday
                    }
                    return false
                }
            case .lastWeek:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
                        let startOfLastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
                        let endOfLastWeek = Calendar.current.date(byAdding: .day, value: -1, to: startOfWeek)!



                        return postedAt >= startOfLastWeek && postedAt <= endOfLastWeek
                    }
                    return false
                }
                
            case .lastMonth:
                announcementsInPeriod = removableAnnouncements.filter { announcement in
                    if let postedAt = announcement.postedAt {
                        // Get the first day of the current month
                        let firstOfCurrentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
                        // Subtract 1 month to get the first day of the previous month
                        let firstOfPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstOfCurrentMonth)!
                        // Get the last day of the previous month by subtracting 1 day from the first of the current month
                        let lastOfPreviousMonth = Calendar.current.date(byAdding: .day, value: -1, to: firstOfCurrentMonth)!
//                        print("first of prev month" + String(describing: firstOfPreviousMonth))
//                        print("last of prev month" + String(describing: lastOfPreviousMonth    ))


                        return postedAt >= firstOfPreviousMonth && postedAt <= lastOfPreviousMonth
                    }
                    return false
                }
            case .previously:
                announcementsInPeriod = removableAnnouncements
            }
            datedAnnouncements[timePeriod] = announcementsInPeriod
                removableAnnouncements.removeAll { announcement in
                    announcementsInPeriod.contains(where: {$0.id == announcement.id})
                }
            
            
        }
        return datedAnnouncements
    }
}
