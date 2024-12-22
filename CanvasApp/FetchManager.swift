//
//  FetchManager.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/19/24.
//

import Foundation
import SwiftUI


struct FetchManager {
    
    private let courseClient = CourseClient()
    private let userClient = UserClient()
    private let moduleClient = ModuleClient()
    private let discussionTopicClient = DiscussionTopicClient()
    private let assignmentClient = AssignmentClient()
    private let pageClient = PageClient()
    private let enrollmentClient = EnrollmentClient()
    
    private var customColorsDict: UserColorCodes! = nil
    
    private let cacheManager = CacheManager()

    private let coursesCacheFile = "courses.json"
    private let userCacheFile = "user.json"
    
    @Binding private var stage: String
    @Binding private var isLoading: Bool
    
    
    
    init(stage: Binding<String>, isLoading: Binding<Bool>) {
        self._stage = stage
        self._isLoading = isLoading
    }
    
    private func populateUsers(wrappers: [CourseWrapper]) async {
        let startTime = DispatchTime.now()

        await withTaskGroup(of: (Int, [EnrollmentType : [User]]?).self) { group in
            for (index, wrapper) in wrappers.enumerated() {
                group.addTask {
                    do {
                        let users = try await courseClient.getUsersEnrolledInCourse(from: wrapper.course)
                        stage = "Preparing user list for course \(wrapper.course.id)"
                        return (index, users)
                    }
                    catch {
                        print("Failed to load user list for course \(wrapper.course.id): \(error)")
                        return (index, nil)
                    }
                }
            }
            for await result in group {
                let (index, users) = result
                if let users = users {
                    wrappers[index].course.usersInCourse = users
                    
                }
            }
            
        }
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("User execution time: \(elapsedTime)")

    }
    
    private func populatePages(wrappers: [CourseWrapper]) async {
        let startTime = DispatchTime.now()

        await withTaskGroup(of: (Int, [Page]?).self) { group in
            for (index, wrapper) in wrappers.enumerated() {
                group.addTask {
                    do {
                        let pages = try await pageClient.retrieveCoursePages(from: wrapper.course)
                        stage = "Preparing pages from course \(wrapper.course.id)"
                        return (index, pages)
                    }
                    catch {
                        print("Failed to load pages for course \(wrapper.course.id): \(error)")
                        return (index, nil)
                    }
                }
            }
            for await result in group {
                let (index, pages) = result
                if let pages = pages {
                    for (var page) in pages {
                        page.attributedText = HTMLRenderer.makeAttributedString(from: page.body ?? "No description was provided")
                        wrappers[index].course.pages.append(page)
                    }
                }
            }
            
        }
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Page execution time: \(elapsedTime)")

    }
    
    private func populateModules(wrappers: [CourseWrapper]) async {
        let startTime = DispatchTime.now()

        await withTaskGroup(of: (Int, [Module]?).self) { group in
            for (index, wrapper) in wrappers.enumerated() {
                group.addTask {
                    do {
                        var modules = try await moduleClient.getModules(from: wrapper.course)
                        // this kinda sucks, but we need to contact Canvas for the pages
                        modules = try await moduleClient.linkModuleItemsToPages(from: wrapper.course, fromModules: modules)
                        stage = "Preparing modules for \(wrapper.course.id)"

                        return (index, modules)
                    }
                    catch {
                        print("Failed to load modules for course \(wrapper.course.id): \(error)")
                        return (index, nil)
                    }
                }
            }
            for await result in group {
                let (index, modules) = result
                if let modules = modules {

                    wrappers[index].course.modules = modules
                }
            }
        }
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Module execution time: \(elapsedTime)")
    }
    
    private func populateAnnouncements(wrappers: [CourseWrapper]) async {
        let startTime = DispatchTime.now()

        await withTaskGroup(of: (Int, [DiscussionTopic]?).self) { group in
            for (index, wrapper) in wrappers.enumerated() {
                group.addTask {
                    do {
                        let announcements = try await discussionTopicClient.getDiscussionTopicsFromCourse(from: wrapper.course, getAnnouncements: true)
                        stage = "Preparing announcements for course \(wrapper.course.id)"
                        return (index, announcements)
                    }
                    catch {
                        print("Failed to load announcements for course \(wrapper.course.id): \(error)")
                        return (index, nil)
                    }
                }
            }
            for await result in group {
                let (index, announcements) = result
                if var announcements = announcements {
                    for i in announcements.indices {
                        announcements[i].attributedText = HTMLRenderer.makeAttributedString(from: announcements[i].body ?? "No description was provided")
                    }
                    
                    wrappers[index].course.announcements = announcements
                    wrappers[index].course.sortAnnouncementsByRecency()
                }
            }
            
        }
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTime = Double(nanoTime) / 1_000_000_000
        print("Announcement execution time: \(elapsedTime)")
    }
    
    private func populateAssignments(wrappers: [CourseWrapper]) async {
        let startTime = DispatchTime.now()

        await withTaskGroup(of: (Int, [Assignment]?).self) { group in
            for (index, wrapper) in wrappers.enumerated() {
                group.addTask {
                    do {
                        let assignments = try await assignmentClient.getAssignmentsFromCourse(from: wrapper.course)
                        stage = "Preparing assignments from course: \(wrapper.course.id)"
                        return (index, assignments)
                    }
                    catch {
                        print("Failed to load assignments for course \(wrapper.course.id): \(error)")
                        return (index, nil)
                    }
                }
            }
            for await result in group {
                let (index, assignments) = result
                if var assignments = assignments {
                    
                    for i in assignments.indices {
                            assignments[i].attributedText = HTMLRenderer.makeAttributedString(from: assignments[i].body ?? "No description was provided")
                            
                            // Update linked assignments in modules
                            for moduleIndex in wrappers[index].course.modules.indices {
                                guard var moduleItems = wrappers[index].course.modules[moduleIndex].items else { continue }
                                
                                for itemIndex in moduleItems.indices 
                                where (moduleItems[itemIndex].type == .assignment && moduleItems[itemIndex].contentID == assignments[i].id)
                                || (moduleItems[itemIndex].type == .quiz && moduleItems[itemIndex].contentID == assignments[i].quizID) {
                                    moduleItems[itemIndex].linkedAssignment = assignments[i]
                                    let isQuiz = moduleItems[itemIndex].type == .quiz ? true : false
                                    moduleItems[itemIndex].linkedAssignment?.isQuiz = isQuiz
                                }
                                
                                // Write the modified items back to the module
                                wrappers[index].course.modules[moduleIndex].items = moduleItems
                            }
                        }
                    
                    wrappers[index].course.assignments = assignments
                    wrappers[index].course.sortAssignmentsByDueDate()
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
        let validCourseIDs = Set(temp.map{$0.course.id})
        
        let filteredGroups = groups.filter { group in
            if let groupID = group.courseID {
                return validCourseIDs.contains(groupID)
            }
            return false
        }
        MainUser.selfUser?.groups = filteredGroups
    }
    
    
    private func prepareInitialCourses() async -> [CourseWrapper] {
           let startTime = DispatchTime.now()

           // Attempt to load cached courses
           var courses: [Course]
           if let cachedCourses: [Course] = try? cacheManager.load(from: coursesCacheFile) {
               print("Loaded courses from cache")
               courses = cachedCourses
           } else {
               print("Fetching courses from network")
               courses = await courseClient.getCoursesByCurrentTerm()!
           }

           // Prepare CourseWrappers
           let tempCourseWrappers = courses.map { course in
               let wrappedCourse = CourseWrapper(course: course)
               wrappedCourse.course.color = MainUser.selfCourseColors?.getHexCode(courseID: course.id) ?? "#000000"
               wrappedCourse.course.syllabusAttributedString = HTMLRenderer.makeAttributedString(from: course.syllabusBody ?? "")
               
               wrappedCourse.fieldsNeedingPopulation.updateValue(wrappedCourse.course.usersInCourse.isEmpty, forKey: "users")
               wrappedCourse.fieldsNeedingPopulation.updateValue(wrappedCourse.course.pages.isEmpty, forKey: "pages")
               wrappedCourse.fieldsNeedingPopulation.updateValue(wrappedCourse.course.announcements.isEmpty, forKey: "announcements")
               wrappedCourse.fieldsNeedingPopulation.updateValue(wrappedCourse.course.modules.isEmpty, forKey: "modules")
               wrappedCourse.fieldsNeedingPopulation.updateValue(wrappedCourse.course.assignments.isEmpty, forKey: "assignments")
               
               return wrappedCourse
           }


           let endTime = DispatchTime.now()
           let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
           let elapsedTime = Double(nanoTime) / 1_000_000_000
           print("Course preparation execution time: \(elapsedTime)")

           return tempCourseWrappers
       }
    
        
    
    
    
    private func prepareUser() async -> User {
        var user: User?
            // Attempt to load cached user data
            if let cachedUser: User = try? cacheManager.load(from: userCacheFile) {
                print("Loaded user from cache")
                user = cachedUser
            }
            else {
                print("Fetching user from network")
                do {
                    var networkUser = try await userClient.getSelfUser()
                    networkUser.enrollments = try await userClient.getUserEnrollments(from: networkUser)
                    networkUser.groups = try await userClient.getGroupsFromSelf()
                    
                    
                    
                    
                    try cacheManager.save(networkUser, to: userCacheFile)
                    user = networkUser
                }
                catch {
                    print("Failed to fetch or save user: \(error)")
                }
            }
        return user!
        }
    
    
    func fetchUserAndCourses() async {
        do {
            let startTime = DispatchTime.now()
            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileURL = cacheDirectory.appendingPathComponent("courses.json")
            print("Courses cache file is located at: \(fileURL.path)")

            // Prepare user
            let user = await prepareUser()

            // Fetch color info for the user
            MainUser.selfCourseColors = try await userClient.getColorInfoFromSelf()
            MainUser.selfUser = user

            // Prepare CourseWrappers
            let tempCourseWrappers = await prepareInitialCourses()
            
            var wrappersNeedingPopulation: [String : [CourseWrapper]] = ["users" : [], "pages" : [], "modules" : [], "announcements" : [], "assignments" : []]
            
            for wrapper in tempCourseWrappers {
                for (field, truth) in wrapper.fieldsNeedingPopulation {
                    if truth {
                        wrappersNeedingPopulation[field]?.append(wrapper)
                    }
                }
            }

            // Populate data (Users, Pages, Modules, Announcements, Assignments)
            await populateUsers(wrappers: wrappersNeedingPopulation["users"]!)
            await populatePages(wrappers: wrappersNeedingPopulation["pages"]!)
            await populateModules(wrappers: wrappersNeedingPopulation["modules"]!)
            await populateAnnouncements(wrappers: wrappersNeedingPopulation["announcements"]!)
            await populateAssignments(wrappers: wrappersNeedingPopulation["assignments"]!)
            
            filterGroups(temp: tempCourseWrappers)

            // Update UI
            DispatchQueue.main.async {
                do {
                    try cacheManager.save(tempCourseWrappers.map({$0.course}), to: coursesCacheFile)
                } catch {
                    print("Failed to save courses to cache: \(error)")
                }
                isLoading = false
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
