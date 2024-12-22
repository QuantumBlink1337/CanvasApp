

import SwiftUI




    
    struct MainLanding: View {
//        @State private var user: User?
        @State private var name: String = ""
        @State private var isLoading = true
        @State private var stage: String = "Loading course data"
        
        @State private var navigationPath = NavigationPath()
        
        @State private var fetchManager: FetchManager? = nil
        
        
        @State private var tokenEntered = !retrieveAPIToken()
        let columns: [GridItem] = [
            GridItem(.flexible()), // First column
            GridItem(.flexible()), // Second column
            
        ]
        
        
        @ViewBuilder
        func buildCourseList() -> some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(MainUser.selfCourseWrappers) { courseWrapper in
                        CoursePanel(courseWrapper: courseWrapper, navigationPath: $navigationPath)
                            .padding(.all, 4.0).cornerRadius(2).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    }
                }
                .padding()
                    
                }
        }
        
        @ViewBuilder
        func buildGroupList() -> some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(MainUser.selfUser?.groups ??   []) { group in
                       Rectangle()
                    }
                }
                .padding()
                    
                }
        }
        
        @ViewBuilder
        func buildHeader() -> some View {
            HStack {
                let authorURL: String = MainUser.selfUser?.avatarURL ?? "Missing"
                buildAsyncImage(urlString: authorURL, imageWidth: 65, imageHeight: 65, shape: .circle)
                    .padding(.leading)
                Spacer()
                Text("Welcome, \(MainUser.selfUser?.fullName ?? "FULL_NAME")")
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()

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
                            VStack() {
                                buildHeader()
                                ScrollView {
                                    HStack() {
                                        Text("Courses")
                                            .font(.headline)
                                            .fontWeight(.heavy)
                                            .padding(.leading)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                    
                                    Divider()

                                    buildCourseList()
                                    HStack() {
                                        Text("Groups")
                                            .font(.headline)
                                            .fontWeight(.heavy)
                                            .padding(.leading)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                    Divider()
                                    buildGroupList()
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


