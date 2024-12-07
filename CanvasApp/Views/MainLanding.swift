

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
    init(courseWrapper: CourseWrapper, userClient: UserClient) {
        self.courseWrapper = courseWrapper
        let initialColor = (HexToColor(courseWrapper.course.color) ?? .black)
        _color = State(initialValue: initialColor)
        _selectedColor = State(initialValue: initialColor)
        self.userClient = userClient
//        print(String(describing: courseWrapper.course.modules))
        

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
        NavigationStack { 
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: CourseView(courseWrapper: courseWrapper)) {
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

                }.buttonStyle(PlainButtonStyle())
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
        
        
        
        
    }
    
    struct MainLanding: View {
        @State private var courses: [Course] = []
        @State private var courseWrappers: [CourseWrapper] = []
        @State private var user: User?
        @State private var name: String = ""
        @State private var isLoading = true
        private let courseClient = CourseClient()
        private let userClient = UserClient()
        private let moduleClient = ModuleClient()
        private let discussionTopicClient = DiscussionTopicClient()
        private let pageClient = PageClient()
        @State private var tokenEntered = !retrieveAPIToken()
        let columns: [GridItem] = [
            GridItem(.flexible()), // First column
            GridItem(.flexible()), // Second column
        ]
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
                                            page.attributedText = HTMLRenderer.makeAttributedString(from: page.body)
                                            tempCourseWrappers[index].course.pages.append(page)
                                        }
                                    }
                                }
                                
                            }

                            await withTaskGroup(of: (Int, [Module]?).self) { group in
                                for (index, wrapper) in tempCourseWrappers.enumerated() {
                                    group.addTask {
                                        do {
                                            let modules = try await moduleClient.getModules(from: wrapper.course)
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
                                            announcements[i].attributedText = HTMLRenderer.makeAttributedString(from: announcements[i].body)
                                        }
                                        
                                        tempCourseWrappers[index].course.announcements = announcements
                                    }
                                }
                                
                            }

                            DispatchQueue.main.async {
                                courseWrappers = tempCourseWrappers
                                isLoading = false
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
                        ProgressView("Loading course data")
                    }
                    else {
                        NavigationStack {
                            VStack {
                                Text("Courses")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Welcome \(user?.fullName ?? "FULL_NAME")")
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(courseWrappers) { courseWrapper in
                                            CoursePanel(courseWrapper: courseWrapper, userClient: userClient)
                                                .padding(.all, 4.0).cornerRadius(2).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                        }
                                    }
                                    .padding()
                                        
                                    }
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
    #Preview {
        MainLanding()
    }

