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
    
    @Binding private var stage: String
    @Binding private var isLoading: Bool
    
    init(stage: Binding<String>, isLoading: Binding<Bool>) {
        self._stage = stage
        self._isLoading = isLoading
    }
    
    private func populateUsers(wrappers: [CourseWrapper]) async {
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

    }
    
    private func populatePages(wrappers: [CourseWrapper]) async {
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

    }
    
    private func populateModules(wrappers: [CourseWrapper]) async {
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
    }
    
    private func populateAnnouncements(wrappers: [CourseWrapper]) async {
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
    }
    
    private func populateAssignments(wrappers: [CourseWrapper]) async {
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
                                
                                for itemIndex in moduleItems.indices where moduleItems[itemIndex].type == .assignment && moduleItems[itemIndex].contentID == assignments[i].id {
                                    moduleItems[itemIndex].linkedAssignment = assignments[i]
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

    }
    
    private func prepareInitialCourses() async -> [CourseWrapper] {
        let fetchedCourses: [Course] = await courseClient.getCoursesByCurrentTerm()!
        let tempCourseWrappers = fetchedCourses.map { course in
            let wrappedCourse = CourseWrapper(course: course)
            wrappedCourse.course.color = MainUser.selfCourseColors?.getHexCode(courseID: course.id) ?? "#000000"
            wrappedCourse.course.syllabusAttributedString = HTMLRenderer.makeAttributedString(from: course.syllabusBody ?? "")
            return wrappedCourse
        }
        return tempCourseWrappers
    }
    
    
    func fetchUserAndCourses() async {
            do {
                // Fetch user data
                MainUser.selfCourseColors = try await userClient.getColorInfoFromSelf()
                var user = try await userClient.getSelfUser()
                user.enrollments = try await userClient.getUserEnrollments(from: user)
                MainUser.selfUser = user
                
                
                // Fetch courses data
               
                let tempCourseWrappers = await prepareInitialCourses()
                        
                await populateUsers(wrappers: tempCourseWrappers)
                await populatePages(wrappers: tempCourseWrappers)
                await populateModules(wrappers: tempCourseWrappers)
                await populateAnnouncements(wrappers: tempCourseWrappers)
                await populateAssignments(wrappers: tempCourseWrappers)

                DispatchQueue.main.async {
                    isLoading = false
                    MainUser.selfCourseWrappers = tempCourseWrappers
                }
            }
        
            catch {
                print("Failed to fetch user or courses: \(error)")
            }
        }

}
