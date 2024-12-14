

import SwiftUI



struct CoursePanel: View {
    @ObservedObject var courseWrapper: CourseWrapper
    let image_width: CGFloat = 170
    let image_height: CGFloat = 80
    let userClient: UserClient
    
    @State var color: Color
    @State var showColorPicker = false
    @State var selectedColor: Color = .blue
    
    
    
    @State var showTextbox = false
    @State var selectedNickname = ""
    
    @Binding private var navigationPath: NavigationPath
    
    init(courseWrapper: CourseWrapper, userClient: UserClient, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        let initialColor = (HexToColor(courseWrapper.course.color) ?? .black)
        _color = State(initialValue: initialColor)
        _selectedColor = State(initialValue: initialColor)
        self.userClient = userClient
//        print(String(describing: courseWrapper.course.modules))
        self._navigationPath = navigationPath
        
        

    }
    private func updateCourseAndUser() async {
        do {
            _ = try await userClient.updateColorInfoOfCourse(courseID: courseWrapper.course.id, hexCode: (colorToHex(selectedColor) ?? "#FFFFFF"))
            _ = try await userClient.updateNicknameOfCourse(courseID: courseWrapper.course.id, nickname: courseWrapper.course.name ?? courseWrapper.course.courseCode)
                
            
        }
        catch {
            print("Failed to fetch user or courses: \(error)")
        }
        
    }
    var body: some View {
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: CourseView(courseWrapper: courseWrapper, navigationPath: $navigationPath)) {
                    VStack(alignment: .leading) {
                            ZStack(alignment: .topTrailing) {
                                
                                if let urlString = courseWrapper.course.image_download_url, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: image_width, height: image_height)
                                        case .success(let image):
                                            ZStack {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: image_width , height: image_height)
                                                    .clipShape(Rectangle())
                                                Rectangle()
                                                    .frame(width: image_width, height: image_height)
                                                    
                                                    .foregroundStyle(color.opacity(0.5))
                                            }
                                            
                                        case .failure:
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(color)
                                                .frame(width: image_width, height: image_height)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    
                                } else {
                                    Rectangle()
                                        .frame(width: image_width, height: image_height).foregroundStyle(color)
                                }
                             
                                    
                                    
                                }
                            
                            Text(courseWrapper.course.name ?? "Missing name")
                                .font(.body) // Display course name
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                                .padding(.leading, 1.0)
                                .foregroundStyle(color)
                            Text(courseWrapper.course.courseCode)
                                .font(.caption2) // Display course name
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                                .padding(.leading, 1.0)
                        
                        

                    }.background()

                }.buttonStyle(PlainButtonStyle()).tint(.white)

                Menu {
                    Button() {
                        showColorPicker = true
                    } label: {
                        HStack {
                            Text("Choose course color")
                            Image(systemName: "paintbrush.pointed.fill").padding(.top, 20.0).foregroundStyle(.white)
                        }
                    }
                    Button() {
                        showTextbox = true
                    } label: {
                        HStack {
                            Text("Choose course nickname")
                            Image(systemName: "pencil.and.scribble").padding(.top, 20.0).foregroundStyle(.white)
                        }
                    }
                    
                }
                 label: {
                    Image(systemName: "paintpalette.fill").padding(.top, 20.0).foregroundStyle(.white).rotationEffect(.degrees(90))
                 }.padding(1)
                
                if showColorPicker {
                            // Dimmed background
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    // Dismiss the color picker if the user taps outside it
                                    showColorPicker = false
                                }

                            // Modal with ColorPicker
                            VStack {

                                ColorPicker("Choose a color", selection: $selectedColor)
                                    .labelsHidden()

                                Button("Done") {
                                    showColorPicker = false
                                    courseWrapper.course.color = colorToHex(selectedColor) ?? "#FFFFFF"
                                    color = HexToColor(courseWrapper.course.color) ?? .white
                                    Task {
                                        let _: () = await updateCourseAndUser()
                                    }
                                    
                                    
                                }
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .frame(width: image_width, height: image_height+20)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }
                if showTextbox {
                            // Dimmed background
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    // Dismiss the color picker if the user taps outside it
                                    showTextbox = false
                                }

                            // Modal with ColorPicker
                            VStack {

                                TextField("Choose a nickname", text: $selectedNickname)
                                    .labelsHidden()

                                Button("Done") {
                                    showTextbox = false
                                    courseWrapper.course.name = selectedNickname
                                    Task {
                                        let _: () = await updateCourseAndUser()
                                    }
                                    
                                    
                                }
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .frame(width: image_width, height: image_height+20)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }

                }
            
            
    }
        
        
        
        
    }
    
    struct MainLanding: View {
        @State private var courses: [Course] = []
        @State private var courseWrappers: [CourseWrapper] = []
        @State private var user: User?
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
        @State private var tokenEntered = !retrieveAPIToken()
        let columns: [GridItem] = [
            GridItem(.flexible()), // First column
            GridItem(.flexible()), // Second column
        ]
//        private func fetchSubmissionsFromAssignments(temp tempCourseWrappers: [CourseWrapper]) async {
//            await withTaskGroup(of: (Int, [Submission]?).self) { group in
//                for (index, wrapper) in tempCourseWrappers.enumerated() {
//                    group.addTask {
//                        do {
//                            let pages = try await pageClient.retrieveCoursePages(from: wrapper.course)
//                            stage = "Preparing pages from course \(wrapper.course.id)"
//                            return (index, pages)
//                        }
//                        catch {
//                            print("Failed to load pages for course \(wrapper.course.id): \(error)")
//                            return (index, nil)
//                        }
//                    }
//                }
//                for await result in group {
//                    let (index, pages) = result
//                    if let pages = pages {
//                        for (var page) in pages {
//                            page.attributedText = HTMLRenderer.makeAttributedString(from: page.body ?? "No description was provided")
//                            tempCourseWrappers[index].course.pages.append(page)
//                        }
//                    }
//                }
//                
//            }
//        }
        
        
        
        private func fetchUserAndCourses() async {
                do {
                    // Fetch user data
                    let fetchedUser = try await userClient.getSelfUser()
                    let customColorsDict = try await userClient.getColorInfoFromSelf()
                    user = fetchedUser
                    
                    // Fetch courses data
                   
                        if let fetchedCourses = await courseClient.getCoursesByCurrentTerm() {
                            let tempCourseWrappers = fetchedCourses.map { course in
                                let wrappedCourse = CourseWrapper(course: course)
                                wrappedCourse.course.color = customColorsDict.getHexCode(courseID: course.id) ?? "#000000"
                                return wrappedCourse
                                
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
                            await withTaskGroup(of: (Int, [Enrollment]?).self) { group in
                                for (index, _) in tempCourseWrappers.enumerated() {
                                    group.addTask {
                                        do {
                                            let enrollments = try await enrollmentClient.getCourseEnrollmentsForUser(from: user!)
                                            stage = "Preparing enrollments for user"
                                            return (index, enrollments)
                                        }
                                        catch {
                                            print("Failed to load enrollments \(error)")
                                            return (index, nil)
                                        }
                                    }
                                }
                                for await result in group {
                                    let (_, enrollments) = result
                                    if let enrollments = enrollments {
                                        for i in enrollments.indices {
                                            if let wrapper = tempCourseWrappers.first(where: {$0.course.id == enrollments[i].courseID}) {
                                                var updatedCourse = wrapper.course
                                                updatedCourse.enrollment = enrollments[i]
                                                wrapper.course = updatedCourse
                                            }
                                        }
                                    }
                                }
                                
                            }
                            await withTaskGroup(of: (Int, [Module]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
                                    group.addTask {
                                        do {
                                            let modules = try await moduleClient.getModules(from: wrapper.course)
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
                                        }
                                        tempCourseWrappers[index].course.assignments = assignments
                                        tempCourseWrappers[index].course.sortAssignmentsByDueDate()
                                    }
                                }
                                
                            }
//                            await withTaskGroup(of: (Int, [[Submission]]?).self) { group in
//                                for (index, wrapper) in tempCourseWrappers.enumerated() {
//                                    group.addTask {
//                                        var submissionList: [[Submission]] = []
//                                    
//                                            for assignment in wrapper.course.assignments {
//                                                print("\(assignment.id), course id: \(wrapper.course.id)")
//                                                do {
//                                                    let submissions = try await assignmentClient.getSubmissionForAssignment(from: assignment)
//                                                    submissionList.append(submissions)
//                                                    stage = "Preparing submissions of assignment \(assignment.id) from course: \(wrapper.course.id)"
//                                                }
//                                                catch {
//                                                    print("Failed to load submissions for assignment \(assignment.id) for course \(wrapper.course.id): \(error)")
//                                                    return (index, nil)
//                                                }
//                                            }
//                                        return (index, submissionList)
//
//                                    }
//                                }
//                                for await result in group {
//                                    let (index, submissionList) = result
//                                    if let submissionList = submissionList {
//                                        // Assign submissions back to the corresponding course assignments
//                                        for (assignmentIndex, submissions) in submissionList.enumerated() {
//                                            tempCourseWrappers[index].course.assignments[assignmentIndex].submissions = submissions
//                                        }
//                                    }
//                                }
//                                
//                            }


                            DispatchQueue.main.async {
                                courseWrappers = tempCourseWrappers
                                isLoading = false
                                GlobalTracking.courses = courseWrappers
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
                        NavigationStack(path: $navigationPath) {
                            VStack {
                                Text("Courses")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Welcome \(user?.fullName ?? "FULL_NAME")")
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(courseWrappers) { courseWrapper in
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
                                
                            }
                        
                        }

                    }
            }.task() {
                    await fetchUserAndCourses()
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
//    #Preview {
//        MainLanding()
//    }

