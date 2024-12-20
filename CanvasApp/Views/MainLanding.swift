

import SwiftUI




    
    struct MainLanding: View {
//        @State private var user: User?
        @State private var name: String = ""
        @State private var isLoading = true
        @State private var stage: String = "Loading course data"
        
        @State private var navigationPath = NavigationPath()
        
        
        private let courseClient = CourseClient()
        private let userClient = UserClient()
        private let moduleClient = ModuleClient()
        private let discussionTopicClient = DiscussionTopicClient()
        private let assignmentClient = AssignmentClient()
        private let pageClient = PageClient()
        private let enrollmentClient = EnrollmentClient()
        
        @State private var fetchManager: FetchManager? = nil
        
        
        
        
        @State private var tokenEntered = !retrieveAPIToken()
        let columns: [GridItem] = [
            GridItem(.flexible()), // First column
            GridItem(.flexible()), // Second column
            
        ]
        
        
        private func fetchUserAndCourses() async {
                do {
                    // Fetch user data
                    let customColorsDict = try await userClient.getColorInfoFromSelf()
                    var user = try await userClient.getSelfUser()
                    user.enrollments = try await userClient.getUserEnrollments(from: user)
                    MainUser.selfUser = user
                    
                    
                    // Fetch courses data
                   
                        if let fetchedCourses = await courseClient.getCoursesByCurrentTerm() {
                            let tempCourseWrappers = fetchedCourses.map { course in
                                let wrappedCourse = CourseWrapper(course: course)
                                wrappedCourse.course.color = customColorsDict.getHexCode(courseID: course.id) ?? "#000000"
                                wrappedCourse.course.syllabusAttributedString = HTMLRenderer.makeAttributedString(from: course.syllabusBody ?? "")
                                return wrappedCourse
                                
                            }
                            await withTaskGroup(of: (Int, [EnrollmentType : [User]]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
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
                                        tempCourseWrappers[index].course.usersInCourse = users
                                        
                                    }
                                }
                                
                            }
                            await withTaskGroup(of: (Int, [Page]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
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
                                            tempCourseWrappers[index].course.pages.append(page)
                                        }
                                    }
                                }
                                
                            }
                            await withTaskGroup(of: (Int, [Module]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
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

                                        tempCourseWrappers[index].course.modules = modules
                                    }
                                    
                                    
                                    
                                    
                                }
                                
                            }
                            await withTaskGroup(of: (Int, [DiscussionTopic]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
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
                                        
                                        tempCourseWrappers[index].course.announcements = announcements
                                        tempCourseWrappers[index].course.sortAnnouncementsByRecency()
                                    }
                                }
                                
                            }
                            await withTaskGroup(of: (Int, [Assignment]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
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
                                                for moduleIndex in tempCourseWrappers[index].course.modules.indices {
                                                    guard var moduleItems = tempCourseWrappers[index].course.modules[moduleIndex].items else { continue }
                                                    
                                                    for itemIndex in moduleItems.indices where moduleItems[itemIndex].type == .assignment && moduleItems[itemIndex].contentID == assignments[i].id {
                                                        moduleItems[itemIndex].linkedAssignment = assignments[i]
                                                    }
                                                    
                                                    // Write the modified items back to the module
                                                    tempCourseWrappers[index].course.modules[moduleIndex].items = moduleItems
                                                }
                                            }
                                        
                                        tempCourseWrappers[index].course.assignments = assignments
                                        tempCourseWrappers[index].course.sortAssignmentsByDueDate()
                                    }
                                }
                
                            }
                            DispatchQueue.main.async {
                                isLoading = false
                                MainUser.selfCourseWrappers = tempCourseWrappers
                            }
                    }
                } 
            
                catch {
                    print("Failed to fetch user or courses: \(error)")
                }
            }
        var body: some View {
            VStack {
                if !tokenEntered {
                    TokenManip(tokenEntered: $tokenEntered)
                }
                else {
                    if (isLoading) {
                        ProgressView(stage)
                    }
                    else {
                        CustomNavigationStack(content: {
                            VStack {
                                Text("Courses")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Welcome \(MainUser.selfUser?.fullName ?? "FULL_NAME")")
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(MainUser.selfCourseWrappers) { courseWrapper in
                                            CoursePanel(courseWrapper: courseWrapper, userClient: userClient, navigationPath: $navigationPath)
                                                .padding(.all, 4.0).cornerRadius(2).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                        }
                                    }
                                    .padding()
                                        
                                    }
                                }
                            .navigationDestination(for: CourseWrapper.self) { course in
                                    CourseView(courseWrapper: course, navigationPath: $navigationPath)
                                }
                                
                            }, path: $navigationPath)
                        
                        }

                    }
            }.task() {
                await fetchManager?.fetchUserAndCourses()
            }
            .onAppear() {
                fetchManager = FetchManager(stage: $stage, isLoading: $isLoading)
            }
        }
    }
struct TokenManip: View {
    @State private var api: String = ""
    @Binding var tokenEntered: Bool
    var body: some View {
        VStack {
            Text("Welcome to Portrait")
            Text("Please enter token from Canvas")
            Link("Here is a guide on how to create one", destination: URL(string: "https://community.canvaslms.com/t5/Canvas-Basics-Guide/How-do-I-manage-API-access-tokens-in-my-user-account/ta-p/615312")!)
            TextField("Enter token", text: $api)
            Button("Done") {
                
                Task {
                    storeAPIToken(api:api)
                    tokenEntered = true
                }
            }
        }
    }
}


